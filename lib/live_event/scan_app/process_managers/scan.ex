# A process manager is responsible for coordinating one or more aggregates
#  This process manager is responsible for coordinating the scan
#  The scan is going to be multiple steps, start, find associated domains, find subdomains for each associated domain, once all of those are completed then we will run the features process and finally complete.

defmodule LiveEvent.ScanApp.ProcessManagers.Scan do
  @doc """
    This process manager is responsible for coordinating the scan
    The scan is going to be multiple steps, start, find associated domains, find subdomains for each associated domain, once all of those are completed then we will run the features process and finally complete.
    I listen to events and create commands

    * ScanStarted -> :start
    * DiscoveredDomains -> n: DiscoverSubdomains
    * DiscoverSubdomainsRequested -> Nothing
    * DiscoveredSubdomains -> [condition: pending_domains == []] -> CompleteScan, :end

  """
  use Commanded.ProcessManagers.ProcessManager,
    application: LiveEvent.ScanApp.Application,
    name: __MODULE__,
    idle_timeout: :timer.minutes(2)

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
    DiscoverSubdomainsRequest,
    CompleteScan,
    FailScan
  }

  @type status :: :started | :domains_discovered | :subdomains_discovered | :completed | :failed

  @max_domain_retries 3
  @max_subdomain_retries 3

  @derive Jason.Encoder
  defstruct [
    :scan_id,
    :status,
    domain_retries: 0,
    subdomain_retries: 0,
    # Domains we have to discover
    pending_domains: [],
    # Domains that have ongoing requests out
    requested_domains: []
  ]

  # Router
  def interested?(%ScanStarted{scan_id: scan_id}), do: {:start, scan_id}
  def interested?(%DiscoverDomainsRequested{scan_id: scan_id}), do: {:continue, scan_id}
  def interested?(%DiscoverDomainsSucceeded{scan_id: scan_id}), do: {:continue, scan_id}
  def interested?(%DiscoverDomainsFailed{scan_id: scan_id}), do: {:continue, scan_id}
  def interested?(%DiscoverSubdomainsRequested{scan_id: scan_id}), do: {:continue, scan_id}
  def interested?(%DiscoverSubdomainsSucceeded{scan_id: scan_id}), do: {:continue, scan_id}
  def interested?(%DiscoverSubdomainsFailed{scan_id: scan_id}), do: {:continue, scan_id}
  def interested?(%ScanFailed{scan_id: scan_id}), do: {:stop, scan_id}
  def interested?(%ScanCompleted{scan_id: scan_id}), do: {:stop, scan_id}
  def interested?(_event), do: false

  # Command dispatch
  def handle(%__MODULE__{pending_domains: pending_domains}, %DiscoverDomainsSucceeded{
        scan_id: scan_id,
        associated_domains: associated_domains
      }) do
    Enum.map(pending_domains ++ associated_domains, fn d ->
      %DiscoverSubdomainsRequest{scan_id: scan_id, domain: d}
    end)
  end

  def handle(%__MODULE__{domain_retries: domain_retries}, %DiscoverDomainsFailed{
        scan_id: scan_id
      })
      when domain_retries >= @max_domain_retries do
    %FailScan{scan_id: scan_id, error: "Max DomainDiscovery retries reached"}
  end

  # When we discovered subdomains, we track the completion of the subdomain discovery step.
  # If we've completed all the subdomain discovery, we can call the scan complete.
  def handle(
        %__MODULE__{scan_id: scan_id, pending_domains: pending_domains} =
          _state,
        %DiscoverSubdomainsSucceeded{
          domain: domain
        }
      ) do
    case List.delete(pending_domains, domain) do
      [] ->
        %CompleteScan{scan_id: scan_id}

      _ ->
        []
    end
  end

  def handle(%__MODULE__{subdomain_retries: subdomain_retries}, %DiscoverSubdomainsFailed{
        scan_id: scan_id
      })
      when subdomain_retries >= @max_subdomain_retries do
    %FailScan{scan_id: scan_id, error: "Max SubdomainDiscovery retries reached"}
  end

  # State mutators
  def apply(%__MODULE__{} = state, %ScanStarted{scan_id: scan_id}) do
    %__MODULE__{state | scan_id: scan_id, status: :started}
  end

  def apply(%__MODULE__{} = state, %DiscoverDomainsRequested{scan_id: scan_id, domain: domain}) do
    %__MODULE__{
      state
      | scan_id: scan_id,
        pending_domains: [domain | state.pending_domains]
    }
  end

  def apply(%__MODULE__{} = state, %DiscoverDomainsSucceeded{associated_domains: domains}) do
    %__MODULE__{
      state
      | status: :discovering_subdomains,
        pending_domains: state.pending_domains ++ domains
    }
  end

  def apply(%__MODULE__{} = state, %DiscoverDomainsFailed{}) do
    %__MODULE__{state | domain_retries: state.domain_retries + 1}
  end

  def apply(%__MODULE__{requested_domains: domains} = state, %DiscoverSubdomainsRequested{
        domain: domain
      }) do
    %__MODULE__{state | requested_domains: [domain | domains]}
  end

  def apply(%__MODULE__{} = state, %DiscoverSubdomainsSucceeded{domain: domain}) do
    %__MODULE__{
      state
      | pending_domains: List.delete(state.pending_domains, domain)
    }
  end

  def apply(%__MODULE__{} = state, %DiscoverSubdomainsFailed{}) do
    %__MODULE__{state | subdomain_retries: state.subdomain_retries + 1}
  end

  def apply(%__MODULE__{} = state, %ScanCompleted{}) do
    %__MODULE__{state | status: :completed}
  end
end
