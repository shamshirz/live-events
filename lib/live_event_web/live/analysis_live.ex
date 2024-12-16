defmodule LiveEventWeb.AnalysisLive do
  use LiveEventWeb, :live_view
  alias LiveEvent.App.Projectors.Analysis
  alias LiveEvent.App.Commands.StartJob
  alias LiveEvent.App.Application

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(LiveEvent.PubSub, "analyses")
    end

    analyses = Analysis.all()
    {:ok, assign(socket, analyses: analyses)}
  end

  def handle_info({:analysis_updated, updated_analysis}, socket) do
    analyses =
      socket.assigns.analyses
      |> Enum.reject(fn {job_id, _} -> job_id == updated_analysis.job_id end)
      |> Kernel.++([{updated_analysis.job_id, updated_analysis}])
      |> Enum.sort_by(
        fn {_, analysis} ->
          case analysis do
            %{started_at: started_at} -> DateTime.to_unix(started_at)
            # Default to oldest for entries without timestamp
            _ -> 0
          end
        end,
        :desc
      )

    {:noreply, assign(socket, analyses: analyses)}
  end

  def handle_event("start-job", _params, socket) do
    job_id = "job_#{:rand.uniform(999_999)}"

    :ok =
      Application.dispatch(%StartJob{
        job_id: job_id
      })

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-3xl">
      <div class="flex justify-between items-center mb-6">
        <h1 class="text-2xl font-bold">Document Analyses</h1>
        <button
          class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
          phx-click="start-job"
        >
          Start New Analysis
        </button>
      </div>

      <div class="space-y-4">
        <%= for {job_id, analysis} <- @analyses do %>
          <div class="p-4 border rounded-lg shadow">
            <div class="flex justify-between items-center">
              <h3 class="text-lg font-semibold">Job: {job_id}</h3>
              <span class={[
                "px-2 py-1 rounded text-sm",
                status_color(analysis.status)
              ]}>
                {analysis.status}
              </span>
            </div>

            <%= if analysis.total_pages do %>
              <div class="mt-2">
                <div class="w-full bg-gray-200 rounded-full h-2.5">
                  <div
                    class="bg-blue-600 h-2.5 rounded-full"
                    style={"width: #{progress_percentage(analysis)}%"}
                  >
                  </div>
                </div>
                <div class="text-sm text-gray-600 mt-1">
                  {analysis.processed_pages} / {analysis.total_pages} pages processed
                </div>
              </div>
            <% end %>

            <%= if length(analysis.active_batch_ids) > 0 do %>
              <div class="mt-3 flex flex-wrap gap-2">
                <%= for batch_id <- analysis.active_batch_ids do %>
                  <span class="px-2 py-1 bg-blue-100 text-blue-800 text-xs rounded-full">
                    Batch {String.replace_prefix(batch_id, "#{job_id}-", "")}
                  </span>
                <% end %>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp status_color(status) do
    case status do
      :calculating_pages -> "bg-yellow-100 text-yellow-800"
      :in_progress -> "bg-blue-100 text-blue-800"
      :analyzing_results -> "bg-purple-100 text-purple-800"
      :completed -> "bg-green-100 text-green-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end

  defp progress_percentage(%{total_pages: total, processed_pages: processed})
       when is_number(total) and total > 0 do
    Float.round(processed / total * 100, 1)
  end

  defp progress_percentage(_), do: 0
end
