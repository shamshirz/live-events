# ---
# Excerpted from "Real-World Event Sourcing",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit https://pragprog.com/titles/khpes for more book information.
# ---
defmodule LiveEvent.App.Projectors.Analysis do
  alias LiveEvent.App.Events.JobStarted
  alias LiveEvent.App.Events.TotalPagesSet
  alias LiveEvent.App.Events.PagesProcessed
  alias LiveEvent.App.Events.AllPagesProcessed
  alias LiveEvent.App.Events.JobCompleted

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
      active_batch_ids: []
    }

    :ets.insert(:analysis, {job_id, analysis})

    :ok
  end

  def handle(
        %TotalPagesSet{
          job_id: job_id,
          total_pages: total_pages
        },
        _metadata
      ) do
    update(job_id, %{status: :in_progress, total_pages: total_pages})
    :ok
  end

  def handle(
        %PagesProcessed{
          job_id: job_id,
          page_count: page_count
        },
        _metadata
      ) do
    update(job_id, %{processed_pages: page_count})
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
    :ets.insert(:analysis, {job_id, Map.merge(old_analysis, map)})
  end

  def get(job_id) do
    [{^job_id, analysis}] = :ets.lookup(:analysis, job_id)
    analysis
  end

  def all do
    :ets.tab2list(:analysis)
  end
end
