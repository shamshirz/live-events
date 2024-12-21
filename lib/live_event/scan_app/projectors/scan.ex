defmodule LiveEvent.ScanApp.Projectors.Scan do
  @doc """
  Projector
  In projections, should I be reading my own data to update it after an event?
  eg. New event for a scan_id comes in, I want to update the exiting entry, which means I need to query for it.

  This projector has 1 entry per scan_id.
  """
  alias LiveEvent.ScanApp.Events.{
    ScanStarted,
    DiscoverDomainsSucceeded,
    DiscoverSubdomainsSucceeded,
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

  # metadata
  # %{
  #   :causation_id => "db1ebd30-7d3c-40f7-87cd-12cd9966df32",
  #   :correlation_id => "1599630b-9c38-433c-9548-0dd793108ba0",
  #   :created_at => #DateTime<2017-10-30 11:19:56.178901Z>,
  #   :event_id => "5e4a0f38-385b-4d57-823b-a1bcf705b7bb",
  #   :event_number => 12345,
  #   :stream_id => "e42a588d-2cda-4314-a471-5d008cce01fc",
  #   :stream_version => 1,
  #   "issuer_id" => "0768d69a-d2b7-48f4-d0e9-083a97f7ebe0",
  #   "user_id" => "user@example.com"
  # }

  def handle(%ScanStarted{scan_id: scan_id, domain: domain}, metadata) do
    scan = %{
      scan_id: scan_id,
      domain: domain,
      status: :started,
      domains: [],
      subdomains: %{},
      score: nil,
      created_at: metadata.created_at,
      duration_seconds: nil
    }

    :ets.insert(:scans, {scan_id, scan})
    broadcast_update(scan)
    :ok
  end

  def handle(%DiscoverDomainsSucceeded{scan_id: scan_id, associated_domains: domains}, _metadata) do
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
        %DiscoverSubdomainsSucceeded{scan_id: scan_id, domain: domain, subdomains: subdomains},
        _metadata
      ) do
    update(scan_id, %{status: :discovering_subdomains, subdomains: %{domain => subdomains}})

    :ok
  end

  def handle(%ScanCompleted{scan_id: scan_id, score: score}, _metadata) do
    [{^scan_id, scan}] = :ets.lookup(:scans, scan_id)

    duration_seconds = DateTime.diff(DateTime.utc_now(), scan.created_at)

    update(scan_id, %{
      status: :completed,
      score: score,
      completed_at: DateTime.utc_now(),
      duration_seconds: duration_seconds
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
