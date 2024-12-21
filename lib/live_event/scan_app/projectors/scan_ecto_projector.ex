defmodule LiveEvent.ScanApp.Projectors.ScanEctoProjector do
  use Commanded.Projections.Ecto,
    application: LiveEvent.ScanApp.Application,
    repo: LiveEvent.Repo,
    name: "scan_projection"

  alias LiveEvent.ScanApp.Events.{
    ScanStarted,
    DiscoverDomainsSucceeded,
    DiscoverSubdomainsSucceeded,
    DiscoverSubdomainsRequested,
    ScanCompleted,
    ScanFailed,
    ScanTimedOut
  }

  alias Ecto.Multi
  alias LiveEvent.ScanApp.Projectors.ScanProjection
  alias Phoenix.PubSub

  project(%ScanStarted{} = event, metadata, fn multi ->
    scan = %{
      scan_id: event.scan_id,
      domain: event.domain,
      status: :started,
      created_at: metadata.created_at
    }

    multi
    |> Ecto.Multi.insert(:scan, ScanProjection.changeset(%ScanProjection{}, scan))
    |> Multi.run(:broadcast, fn _repo, %{scan: scan} ->
      broadcast_update(scan)
      {:ok, scan}
    end)
  end)

  project(%DiscoverDomainsSucceeded{} = event, _metadata, fn multi ->
    update_scan(multi, event.scan_id, %{
      status: :discovering_subdomains,
      domains: event.associated_domains
    })
  end)

  project(%DiscoverSubdomainsRequested{} = event, _metadata, fn multi ->
    update_scan(multi, event.scan_id, fn scan ->
      subdomains = Map.put(scan.subdomains || %{}, event.domain, [])
      %{status: :discovering_subdomains, subdomains: subdomains}
    end)
  end)

  project(%DiscoverSubdomainsSucceeded{} = event, _metadata, fn multi ->
    update_scan(multi, event.scan_id, fn scan ->
      subdomains = Map.put(scan.subdomains || %{}, event.domain, event.subdomains)
      %{status: :discovering_subdomains, subdomains: subdomains}
    end)
  end)

  project(%ScanCompleted{} = event, _metadata, fn multi ->
    update_scan(multi, event.scan_id, fn scan ->
      duration_seconds = DateTime.diff(DateTime.utc_now(), scan.created_at)

      %{
        status: :completed,
        score: event.score,
        completed_at: DateTime.utc_now(),
        duration_seconds: duration_seconds
      }
    end)
  end)

  project(%ScanFailed{} = event, _metadata, fn multi ->
    update_scan(multi, event.scan_id, %{
      status: :failed
    })
  end)

  project(%ScanTimedOut{} = event, _metadata, fn multi ->
    update_scan(multi, event.scan_id, %{
      status: :failed
    })
  end)

  defp update_scan(multi, scan_id, attrs_or_fun) do
    multi
    |> Ecto.Multi.run(:get_scan, fn repo, _changes ->
      case repo.get(ScanProjection, scan_id) do
        nil -> {:error, :not_found}
        scan -> {:ok, scan}
      end
    end)
    |> Ecto.Multi.run(:update_scan, fn repo, %{get_scan: scan} ->
      attrs = if is_function(attrs_or_fun), do: attrs_or_fun.(scan), else: attrs_or_fun

      scan
      |> ScanProjection.changeset(attrs)
      |> repo.update()
    end)
    |> Multi.run(:broadcast, fn _repo, %{update_scan: scan} ->
      broadcast_update(scan)
      {:ok, scan}
    end)
  end

  defp broadcast_update(scan) do
    PubSub.broadcast(
      LiveEvent.PubSub,
      "scans",
      {:scan_updated, scan}
    )

    {:ok, scan}
  end
end
