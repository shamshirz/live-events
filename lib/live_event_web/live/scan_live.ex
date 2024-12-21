defmodule LiveEventWeb.ScanLive do
  use LiveEventWeb, :live_view
  alias LiveEvent.Repo
  alias LiveEvent.ScanApp.Projectors.ScanProjection
  alias LiveEvent.ScanApp.Commands.StartScan
  alias LiveEvent.ScanApp.Application

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(LiveEvent.PubSub, "scans")
    end

    scans =
      ScanProjection
      |> Repo.all()
      |> Enum.map(fn scan -> {scan.scan_id, scan} end)
      |> Enum.sort_by(
        fn {_, scan} ->
          case scan do
            %{created_at: created_at} when not is_nil(created_at) -> DateTime.to_unix(created_at)
            _ -> 0
          end
        end,
        :desc
      )

    {:ok, assign(socket, scans: scans)}
  end

  def handle_info({:scan_updated, updated_scan}, socket) do
    scans =
      socket.assigns.scans
      |> Enum.reject(fn {scan_id, _} -> scan_id == updated_scan.scan_id end)
      |> Kernel.++([{updated_scan.scan_id, updated_scan}])
      |> Enum.sort_by(
        fn {_, scan} ->
          case scan do
            %{created_at: created_at} when not is_nil(created_at) -> DateTime.to_unix(created_at)
            _ -> 0
          end
        end,
        :desc
      )

    {:noreply, assign(socket, scans: scans)}
  end

  def handle_event("start-scan", _params, socket) do
    scan_id = "scan_#{:rand.uniform(999_999)}"

    :ok =
      Application.dispatch(%StartScan{
        scan_id: scan_id,
        domain: "example.com"
      })

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-3xl">
      <div class="flex justify-between items-center mb-6">
        <h1 class="text-2xl font-bold">Domain Scans</h1>
        <button
          class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
          phx-click="start-scan"
        >
          Start New Scan
        </button>
      </div>

      <div class="space-y-4">
        <%= for {scan_id, scan} <- @scans do %>
          <div class={[
            "p-4 rounded-lg shadow relative",
            border_animation(scan.status)
          ]}>
            <div class="flex justify-between items-center">
              <h3 class="text-lg font-semibold">
                {scan.domain}
                <span class="text-sm font-normal text-gray-500">({scan_id})</span>
              </h3>
              <span class={[
                "px-2 py-1 rounded text-sm",
                status_color(scan.status)
              ]}>
                {scan.status}
              </span>
            </div>

            <div class="mt-2 text-sm text-gray-600">
              <%= if scan.domains != [] do %>
                <div class="mt-2">
                  <p class="font-semibold">Associated Domains:</p>
                  <div class="flex flex-wrap gap-2 mt-1">
                    <%= for domain <- scan.domains do %>
                      <span class="px-2 py-1 bg-gray-100 rounded-full">
                        {domain}
                      </span>
                    <% end %>
                  </div>
                </div>
              <% end %>

              <%= if map_size(scan.subdomains) > 0 do %>
                <div class="mt-2">
                  <p class="font-semibold">Subdomains:</p>
                  <%= for {domain, subs} <- scan.subdomains do %>
                    <div class="mt-1">
                      <p class="text-sm text-gray-500">{domain}:</p>
                      <div class="flex flex-wrap gap-2 mt-1">
                        <%= for subdomain <- subs do %>
                          <span class="px-2 py-1 bg-gray-100 rounded-full text-xs">
                            {subdomain}
                          </span>
                        <% end %>
                      </div>
                    </div>
                  <% end %>
                </div>
              <% end %>

              <%= if scan.score do %>
                <div class="mt-2 space-y-1">
                  <p class="font-semibold">Score: {scan.score}</p>
                  <%= if scan.duration_seconds do %>
                    <p class="text-sm text-gray-500">
                      Completed in {format_duration(scan.duration_seconds)}
                    </p>
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>
      </div>
    </div>

    <style>
      @keyframes pulse-border {
        0%, 100% { border-color: rgba(59, 130, 246, 0.3); }
        50% { border-color: rgba(59, 130, 246, 1); }
      }

      .animate-border-progress {
        border: 2px solid rgba(59, 130, 246, 0.3);
        animation: pulse-border 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
      }

      .border-completed {
        border: 2px solid rgba(34, 197, 94, 1);
        transition: border-color 0.3s ease;
      }

      .border-error {
        border: 2px solid rgba(239, 68, 68, 1);
      }
    </style>
    """
  end

  defp status_color(status) do
    case status do
      :completed -> "bg-green-100 text-green-800"
      :failed -> "bg-red-100 text-red-800"
      _ -> "bg-blue-100 text-blue-800"
    end
  end

  defp border_animation(status) do
    case status do
      :completed -> "border-completed"
      :failed -> "border-error"
      _ -> "animate-border-progress"
    end
  end

  defp format_duration(seconds) when seconds < 60 do
    "#{seconds} seconds"
  end

  defp format_duration(seconds) do
    minutes = div(seconds, 60)
    remaining_seconds = rem(seconds, 60)
    "#{minutes} min #{remaining_seconds} sec"
  end
end
