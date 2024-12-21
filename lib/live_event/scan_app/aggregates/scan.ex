defmodule LiveEvent.ScanApp.Aggregates.Scan do
  @doc """
  This is the aggregate for the scan app.
  Accept commands and turn them into events if they pass validation.
  * StartScan -> ScanStarted
  * DiscoverDomains -> DiscoveredDomains
  * DiscoverSubdomainsRequest -> DiscoverSubdomainsRequested
  * DiscoverSubdomains -> DiscoveredSubdomains
  * CompleteScan -> ScanCompleted
  """

  alias LiveEvent.ScanApp.Events.{
    ScanStarted,
    DiscoverDomainsRequested,
    DiscoverDomainsSucceeded,
    DiscoverDomainsFailed,
    DiscoverSubdomainsRequested,
    DiscoverSubdomainsSucceeded,
    DiscoverSubdomainsFailed,
    ScanCompleted,
    ScanFailed
  }

  alias LiveEvent.ScanApp.Commands.{
    StartScan,
    DiscoverDomainsSuccess,
    DiscoverDomainsFail,
    DiscoverSubdomainsRequest,
    DiscoverSubdomainsSuccess,
    DiscoverSubdomainsFail,
    CompleteScan
  }

  alias Commanded.Aggregate.Multi

  @type status :: :started | :domains_discovered | :subdomains_discovered | :completed | :failed

  defstruct [
    :scan_id,
    :domain,
    :status,
    domains: [],
    subdomains: %{},
    score: 0,
    error: nil
  ]

  # Command handlers
  def execute(%__MODULE__{scan_id: nil} = scan, %StartScan{scan_id: scan_id, domain: domain}) do
    scan
    |> Multi.new()
    |> Multi.execute(fn _ -> start_scan(scan_id, domain) end)
    |> Multi.execute(fn _ -> request_domains_discovery(scan_id, domain) end)
  end

  # The domains were discovered and are posted here to be turned into an event.
  def execute(%__MODULE__{status: :started} = _scan, %DiscoverDomainsSuccess{
        scan_id: scan_id,
        associated_domains: associated_domains
      }) do
    [%DiscoverDomainsSucceeded{scan_id: scan_id, associated_domains: associated_domains}]
  end

  def execute(%__MODULE__{status: :started} = _scan, %DiscoverDomainsFail{
        scan_id: scan_id,
        error: error
      }) do
    [%DiscoverDomainsFailed{scan_id: scan_id, error: error}]
  end

  def execute(%__MODULE__{} = _scan, %DiscoverSubdomainsRequest{
        scan_id: scan_id,
        domain: domain
      }) do
    [%DiscoverSubdomainsRequested{scan_id: scan_id, domain: domain}]
  end

  def execute(%__MODULE__{status: :domains_discovered} = _scan, %DiscoverSubdomainsSuccess{
        scan_id: scan_id,
        domain: domain,
        subdomains: subdomains
      }) do
    [
      %DiscoverSubdomainsSucceeded{
        scan_id: scan_id,
        domain: domain,
        subdomains: subdomains
      }
    ]
  end

  def execute(%__MODULE__{status: :domains_discovered} = _scan, %DiscoverSubdomainsFail{
        scan_id: scan_id,
        domain: domain,
        error: error
      }) do
    [
      %DiscoverSubdomainsFailed{
        scan_id: scan_id,
        domain: domain,
        error: error
      }
    ]
  end

  def execute(%__MODULE__{status: :subdomains_discovered} = scan, %CompleteScan{scan_id: scan_id}) do
    score = calculate_score(scan)

    [
      %ScanCompleted{
        scan_id: scan_id,
        score: score,
        domains: scan.domains,
        subdomains: scan.subdomains,
        completed_at: DateTime.utc_now()
      }
    ]
  end

  # State mutators
  def apply(%__MODULE__{} = state, %ScanStarted{scan_id: scan_id, domain: domain}) do
    %__MODULE__{state | scan_id: scan_id, domain: domain, status: :started}
  end

  def apply(%__MODULE__{} = state, %DiscoverDomainsRequested{}) do
    state
  end

  def apply(%__MODULE__{} = state, %DiscoverDomainsSucceeded{
        associated_domains: associated_domains
      }) do
    %__MODULE__{state | domains: associated_domains, status: :domains_discovered}
  end

  def apply(%__MODULE__{} = state, %DiscoverDomainsFailed{}) do
    state
  end

  def apply(%__MODULE__{} = state, %DiscoverSubdomainsRequested{}) do
    state
  end

  def apply(%__MODULE__{} = state, %DiscoverSubdomainsFailed{}) do
    state
  end

  # Fill in domain key with subdomains, if they are all present, set status to subdomains_discovered
  def apply(%__MODULE__{} = state, %DiscoverSubdomainsSucceeded{
        domain: domain,
        subdomains: subdomains
      }) do
    updated_subdomains = Map.put(state.subdomains, domain, subdomains)

    case Enum.all?([state.domain | state.domains], fn domain ->
           Map.has_key?(updated_subdomains, domain)
         end) do
      true ->
        %__MODULE__{state | status: :subdomains_discovered, subdomains: updated_subdomains}

      _ ->
        %__MODULE__{state | subdomains: updated_subdomains}
    end
  end

  def apply(%__MODULE__{} = state, %ScanCompleted{score: score}) do
    %__MODULE__{state | status: :completed, score: score}
  end

  def apply(%__MODULE__{} = state, %ScanFailed{error: error}) do
    %__MODULE__{state | status: :failed, error: error}
  end

  def new(scan_id, domain) do
    %__MODULE__{scan_id: scan_id, domain: domain, status: :started}
  end

  defp start_scan(scan_id, domain) do
    %ScanStarted{scan_id: scan_id, domain: domain}
  end

  defp request_domains_discovery(scan_id, domain) do
    %DiscoverDomainsRequested{scan_id: scan_id, domain: domain}
  end

  defp calculate_score(scan) do
    # Implement your scoring logic here
    # This is a simple example
    domain_count = length(scan.domains)
    subdomain_count = scan.subdomains |> Map.values() |> List.flatten() |> length()
    domain_count * 10 + subdomain_count * 5
  end
end
