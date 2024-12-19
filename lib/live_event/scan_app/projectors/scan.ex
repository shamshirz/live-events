defmodule LiveEvent.ScanApp.Projectors.Scan do
  @doc """
  Projector
  In projections, should I be reading my own data to update it after an event?
  eg. New event for a scan_id comes in, I want to update the exiting entry, which means I need to query for it.

  This projector has 1 entry per scan_id.
  """
  alias LiveEvent.ScanApp.Events.{
    ScanStarted,
    DiscoveredDomains,
    DiscoveredSubdomains,
    DiscoverSubdomainsRequested,
    ScanCompleted
  }

  alias Phoenix.PubSub

  use Commanded.Event.Handler,
    application: LiveEvent.ScanApp.Application,
    name: __MODULE__,
    consistency: :strong

  def init(config) do
    :ets.new(:scans, [:named_table, :set, :public])
    {:ok, config}
  end

  def handle(%ScanStarted{scan_id: scan_id, domain: domain}, _metadata) do
    scan = %{
      scan_id: scan_id,
      domain: domain,
      status: :started,
      domains: [],
      subdomains: %{},
      score: nil,
      started_at: DateTime.utc_now()
    }

    :ets.insert(:scans, {scan_id, scan})
    broadcast_update(scan)
    :ok
  end

  def handle(%DiscoveredDomains{scan_id: scan_id, domains: domains}, _metadata) do
    update(scan_id, %{
      status: :discovering_subdomains,
      domains: domains
    })

    :ok
  end

  def handle(
        %DiscoverSubdomainsRequested{scan_id: scan_id, domain: domain},
        _metadata
      ) do
    update(scan_id, %{status: :discovering_subdomains, subdomains: %{domain => []}})

    :ok
  end

  def handle(
        %DiscoveredSubdomains{scan_id: scan_id, domain: domain, subdomains: subdomains},
        _metadata
      ) do
    update(scan_id, %{status: :discovering_subdomains, subdomains: %{domain => subdomains}})

    :ok
  end

  def handle(%ScanCompleted{scan_id: scan_id, score: score}, _metadata) do
    update(scan_id, %{
      status: :completed,
      score: score,
      completed_at: DateTime.utc_now()
    })

    :ok
  end

  defp update(scan_id, attrs) do
    [{^scan_id, scan}] = :ets.lookup(:scans, scan_id)

    new_scan =
      if Map.has_key?(attrs, :subdomains) do
        extracted_subdomains = Map.get(scan, :subdomains, %{})
        merged_subdomains = Map.merge(extracted_subdomains, attrs.subdomains)
        Map.merge(scan, %{attrs | subdomains: merged_subdomains})
      else
        Map.merge(scan, attrs)
      end

    IO.inspect(new_scan, label: "new_scan")

    :ets.insert(:scans, {scan_id, new_scan})
    broadcast_update(new_scan)
  end

  defp broadcast_update(scan) do
    PubSub.broadcast(
      LiveEvent.PubSub,
      "scans",
      {:scan_updated, scan}
    )
  end

  def get(scan_id) do
    [{^scan_id, scan}] = :ets.lookup(:scans, scan_id)
    scan
  end

  def all do
    :ets.tab2list(:scans)
  end
end
