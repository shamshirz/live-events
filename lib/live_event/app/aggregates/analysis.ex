defmodule LiveEvent.App.Aggregates.Analysis do
  alias LiveEvent.App.Events.PagesProcessed
  alias LiveEvent.App.Events.TotalPagesSet
  alias LiveEvent.App.Events.JobStarted
  alias LiveEvent.App.Events.JobCompleted
  alias Commanded.Aggregate.Multi

  defstruct [
    :job_id,
    :status,
    :total_pages,
    :processed_pages
  ]

  def execute(%__MODULE__{status: nil}, %LiveEvent.App.Commands.StartJob{job_id: job_id}) do
    {:ok, %JobStarted{job_id: job_id}}
  end

  def execute(
        %__MODULE__{status: :in_progress, total_pages: nil},
        %LiveEvent.App.Commands.SetTotalPages{job_id: job_id, total_pages: total_pages}
      ) do
    {:ok, %TotalPagesSet{job_id: job_id, total_pages: total_pages}}
  end

  def execute(
        %__MODULE__{
          processed_pages: processed_pages,
          total_pages: total_pages
        } = state,
        %LiveEvent.App.Commands.ProcessPages{
          job_id: job_id,
          batch_id: batch_id,
          page_count: page_count
        }
      )
      when processed_pages + page_count == total_pages do
    state
    |> Multi.new()
    |> Multi.execute(&pages_processed(&1, batch_id, page_count))
    |> Multi.execute(&all_pages_processed(&1, job_id))
  end

  def execute(
        %__MODULE__{} = state,
        %LiveEvent.App.Commands.ProcessPages{
          batch_id: batch_id,
          page_count: page_count
        }
      ) do
    pages_processed(state, batch_id, page_count)
  end

  def execute(_, %LiveEvent.App.Commands.CompleteJob{job_id: job_id}) do
    {:ok, %JobCompleted{job_id: job_id}}
  end

  # Apply events
  def apply(%__MODULE__{} = job, %JobStarted{job_id: job_id}) do
    %{job | job_id: job_id, status: :in_progress, processed_pages: 0}
  end

  def apply(%__MODULE__{} = job, %TotalPagesSet{job_id: job_id, total_pages: total_pages}) do
    %{job | job_id: job_id, total_pages: total_pages}
  end

  def apply(%__MODULE__{} = job, %PagesProcessed{job_id: job_id, page_count: processed_pages}) do
    %{job | job_id: job_id, processed_pages: processed_pages}
  end

  def apply(%__MODULE__{} = job, %JobCompleted{job_id: job_id}) do
    %{job | job_id: job_id, status: :completed}
  end

  defp all_pages_processed(_state, job_id) do
    {:ok, %JobCompleted{job_id: job_id}}
  end

  defp pages_processed(state, batch_id, page_count) do
    {:ok,
     %PagesProcessed{
       job_id: state.job_id,
       batch_id: batch_id,
       page_count: state.processed_pages + page_count
     }}
  end
end
