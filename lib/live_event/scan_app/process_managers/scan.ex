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
    name: __MODULE__

  alias LiveEvent.ScanApp.Events.{
    ScanStarted,
    DiscoveredDomains,
    DiscoveredSubdomains,
    DiscoverSubdomainsRequested,
    ScanCompleted,
    ScanFailed
  }

  alias LiveEvent.ScanApp.Commands.{
    RequestSubdomainDiscovery,
    CompleteScan
  }

  @derive Jason.Encoder
  defstruct [
    :scan_id,
    :status,
    :pending_domains,
    requested_domains: []
  ]

  # Router
  def interested?(%ScanStarted{scan_id: scan_id}), do: {:start, scan_id}
  def interested?(%DiscoveredDomains{scan_id: scan_id}), do: {:continue, scan_id}
  def interested?(%DiscoverSubdomainsRequested{scan_id: scan_id}), do: {:continue, scan_id}
  def interested?(%DiscoveredSubdomains{scan_id: scan_id}), do: {:continue, scan_id}
  def interested?(%ScanFailed{scan_id: scan_id}), do: {:stop, scan_id}
  def interested?(%ScanCompleted{scan_id: scan_id}), do: {:stop, scan_id}
  def interested?(_event), do: false

  # Command dispatch
  def handle(%__MODULE__{}, %DiscoveredDomains{scan_id: scan_id, domains: domains}) do
    Enum.map(domains, fn d ->
      %RequestSubdomainDiscovery{scan_id: scan_id, domain: d}
    end)
  end

  # On requesting a subdomain, we don't do anything, we await the Gateway to process it, we just track that it happened.
  def handle(
        %__MODULE__{pending_domains: _pending_domains} = _state,
        %DiscoverSubdomainsRequested{
          scan_id: _scan_id,
          domain: _domain
        }
      ) do
    # Maybe here we send info to the Domains aggregate?
    []
  end

  # defstruct [:scan_id, :domain, :subdomains]
  # When we discovered subdomains, we track the completion of the subdomain discovery step.
  # If we've completed all the subdomain discovery, we can call the scan complete.
  def handle(
        %__MODULE__{scan_id: scan_id, pending_domains: pending_domains} =
          _state,
        %DiscoveredSubdomains{
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

  # State mutators
  def apply(%__MODULE__{} = state, %ScanStarted{scan_id: scan_id}) do
    %__MODULE__{state | scan_id: scan_id, status: :started}
  end

  def apply(%__MODULE__{} = state, %DiscoveredDomains{domains: domains}) do
    %__MODULE__{state | status: :discovering_subdomains, pending_domains: domains}
  end

  def apply(%__MODULE__{requested_domains: domains} = state, %DiscoverSubdomainsRequested{
        domain: domain
      }) do
    %__MODULE__{state | requested_domains: [domain | domains]}
  end

  def apply(%__MODULE__{} = state, %DiscoveredSubdomains{domain: domain}) do
    %__MODULE__{
      state
      | pending_domains: List.delete(state.pending_domains, domain)
    }
  end

  def apply(%__MODULE__{} = state, %ScanCompleted{}) do
    %__MODULE__{state | status: :completed}
  end
end
