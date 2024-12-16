defmodule LiveEvent.App.Projectors.Analysis do
  alias LiveEvent.App.Events.JobStarted
  alias LiveEvent.App.Events.TotalPagesSet
  alias LiveEvent.App.Events.PagesProcessed
  alias LiveEvent.App.Events.AllPagesProcessed
  alias LiveEvent.App.Events.JobCompleted
  alias Phoenix.PubSub

  use Commanded.Event.Handler,
    application: LiveEvent.App.Application,
    name: __MODULE__

  def init(config) do
    :ets.new(:analysis, [:named_table, :set, :public])

    {:ok, config}
  end

  def handle(%JobStarted{job_id: job_id}, _metadata) do
    analysis = %{
      job_id: job_id,
      status: :calculating_pages,
      total_pages: nil,
      processed_pages: 0,
      active_batch_ids: [],
      started_at: DateTime.utc_now()
    }

    :ets.insert(:analysis, {job_id, analysis})

    # Broadcast the new analysis
    PubSub.broadcast(
      LiveEvent.PubSub,
      "analyses",
      {:analysis_updated, analysis}
    )

    :ok
  end

  def handle(
        %TotalPagesSet{
          job_id: job_id,
          total_pages: total_pages
        },
        _metadata
      ) do
    # When total pages is set, we'll get batch_ids from the range
    batch_ids =
      1..total_pages
      |> Enum.chunk_every(10)
      |> Enum.map(fn pages -> "#{job_id}-#{hd(pages)}" end)

    update(job_id, %{
      status: :in_progress,
      total_pages: total_pages,
      active_batch_ids: batch_ids
    })

    :ok
  end

  def handle(
        %PagesProcessed{
          job_id: job_id,
          batch_id: batch_id,
          page_count: page_count
        },
        _metadata
      ) do
    [{^job_id, analysis}] = :ets.lookup(:analysis, job_id)

    update(job_id, %{
      processed_pages: page_count,
      active_batch_ids: analysis.active_batch_ids -- [batch_id]
    })

    :ok
  end

  def handle(
        %AllPagesProcessed{
          job_id: job_id
        },
        _metadata
      ) do
    update(job_id, %{status: :analyzing_results})
    :ok
  end

  def handle(%JobCompleted{job_id: job_id}, _metadata) do
    update(job_id, %{status: :completed})
    :ok
  end

  @spec update(job_id :: String.t(), map :: map()) :: boolean()
  defp update(job_id, map) do
    [{^job_id, old_analysis}] = :ets.lookup(:analysis, job_id)
    new_analysis = Map.merge(old_analysis, map)
    :ets.insert(:analysis, {job_id, new_analysis})

    # Broadcast the update
    PubSub.broadcast(
      LiveEvent.PubSub,
      "analyses",
      {:analysis_updated, new_analysis}
    )
  end

  def get(job_id) do
    [{^job_id, analysis}] = :ets.lookup(:analysis, job_id)
    analysis
  end

  def all do
    :ets.tab2list(:analysis)
  end
end
