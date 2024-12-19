defmodule LiveEvent.ScanApp.Aggregates.Scan do
  @doc """
  This is the aggregate for the scan app.
  Accept commands and turn them into events if they pass validation.
  * StartScan -> ScanStarted
  * DiscoverDomains -> DiscoveredDomains
  * RequestSubdomainDiscovery -> DiscoverSubdomainsRequested
  * DiscoverSubdomains -> DiscoveredSubdomains
  * CompleteScan -> ScanCompleted
  """
  alias LiveEvent.ScanApp.Events.{
    ScanStarted,
    DiscoveredDomains,
    DiscoveredSubdomains,
    DiscoverSubdomainsRequested,
    ScanCompleted,
    ScanFailed
  }

  alias LiveEvent.ScanApp.Commands.{
    FailScan,
    StartScan,
    DiscoverDomains,
    DiscoverSubdomains,
    RequestSubdomainDiscovery,
    CompleteScan
  }

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
  def execute(%__MODULE__{scan_id: nil}, %StartScan{scan_id: scan_id, domain: domain}) do
    {:ok, %ScanStarted{scan_id: scan_id, domain: domain, started_at: DateTime.utc_now()}}
  end

  # The domains were discovered and are posted here to be turned into an event.
  def execute(%__MODULE__{status: :started} = _scan, %DiscoverDomains{
        scan_id: scan_id,
        domain: domain,
        associated_domains: associated_domains
      }) do
    {:ok, %DiscoveredDomains{scan_id: scan_id, domains: [domain | associated_domains]}}
  end

  def execute(%__MODULE__{} = _scan, %RequestSubdomainDiscovery{
        scan_id: scan_id,
        domain: domain
      }) do
    {:ok, %DiscoverSubdomainsRequested{scan_id: scan_id, domain: domain}}
  end

  # The subdomains were discovered and are posted here to be turned into an event.
  def execute(%__MODULE__{status: :domains_discovered} = _scan, %DiscoverSubdomains{
        scan_id: scan_id,
        domain: domain,
        subdomains: subdomains
      }) do
    # This is where a gateway or something listens to this event and kicks off the side-effects
    #  We use the DomainsGateway to listen for this event
    {:ok,
     %DiscoveredSubdomains{
       scan_id: scan_id,
       domain: domain,
       subdomains: subdomains
     }}
  end

  def execute(%__MODULE__{status: :subdomains_discovered} = scan, %CompleteScan{scan_id: scan_id}) do
    score = calculate_score(scan)

    {:ok,
     %ScanCompleted{
       scan_id: scan_id,
       score: score,
       domains: scan.domains,
       subdomains: scan.subdomains,
       completed_at: DateTime.utc_now()
     }}
  end

  def execute(%__MODULE__{} = _scan, %FailScan{scan_id: scan_id, error: error}) do
    {:ok, %ScanFailed{scan_id: scan_id, error: error}}
  end

  # State mutators
  def apply(%__MODULE__{} = state, %ScanStarted{scan_id: scan_id, domain: domain}) do
    %__MODULE__{state | scan_id: scan_id, domain: domain, status: :started}
  end

  def apply(%__MODULE__{} = state, %DiscoveredDomains{domains: domains}) do
    %__MODULE__{state | domains: domains, status: :domains_discovered}
  end

  def apply(%__MODULE__{} = state, %DiscoverSubdomainsRequested{}) do
    state
  end

  def apply(%__MODULE__{} = state, %DiscoveredSubdomains{domain: domain, subdomains: subdomains}) do
    updated_subdomains = Map.put(state.subdomains, domain, subdomains)

    case Enum.all?(state.domains, fn domain -> Map.has_key?(updated_subdomains, domain) end) do
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

  defp calculate_score(scan) do
    # Implement your scoring logic here
    # This is a simple example
    domain_count = length(scan.domains)
    subdomain_count = scan.subdomains |> Map.values() |> List.flatten() |> length()
    domain_count * 10 + subdomain_count * 5
  end
end
