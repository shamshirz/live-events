defmodule LiveEvent.App.ProcessManagers.Analysis do
  alias LiveEvent.App.Events.JobCompleted

  alias LiveEvent.App.Events.{
    AllPagesProcessed,
    PagesProcessed,
    JobStarted,
    TotalPagesSet,
    JobCompleted
  }

  alias LiveEvent.DocumentProcessingGateway

  require Logger

  use Commanded.ProcessManagers.ProcessManager,
    application: LiveEvent.App.Application,
    name: __MODULE__

  @derive Jason.Encoder
  defstruct [
    :job_id,
    :status,
    :total_pages,
    :processed_pages,
    :active_batch_ids
  ]

  def interested?(%JobStarted{job_id: job_id}), do: {:start, job_id}

  def interested?(%TotalPagesSet{job_id: job_id}), do: {:continue, job_id}

  def interested?(%PagesProcessed{job_id: job_id}), do: {:continue, job_id}

  def interested?(%AllPagesProcessed{job_id: job_id}), do: {:continue, job_id}

  def interested?(%JobCompleted{job_id: job_id}), do: {:stop, job_id}

  def interested?(_event), do: false

  # Command Dispatch
  def handle(
        %__MODULE__{},
        %JobStarted{
          job_id: job_id
        }
      ) do
    :ok = DocumentProcessingGateway.request_total_pages(job_id)
    []
  end

  def handle(
        %__MODULE__{},
        %TotalPagesSet{
          job_id: job_id,
          total_pages: total_pages
        }
      ) do
    for pages <- Enum.chunk_every(1..total_pages, 10) do
      batch_id = "#{job_id}-#{hd(pages)}"
      :ok = DocumentProcessingGateway.process_pages(job_id, batch_id, length(pages))
    end

    []
  end

  def handle(
        %__MODULE__{},
        %PagesProcessed{
          job_id: _,
          batch_id: _,
          page_count: _
        }
      ) do
    []
  end

  def handle(
        %__MODULE__{},
        %AllPagesProcessed{
          job_id: job_id
        }
      ) do
    :ok = DocumentProcessingGateway.complete_job(job_id)
    []
  end

  def apply(%__MODULE__{} = state, %JobStarted{job_id: job_id} = _evt) do
    %__MODULE__{
      state
      | job_id: job_id,
        status: :processing,
        processed_pages: 0,
        active_batch_ids: []
    }
  end

  def apply(
        %__MODULE__{} = state,
        %TotalPagesSet{job_id: job_id, total_pages: total_pages} = _evt
      ) do
    %__MODULE__{state | job_id: job_id, total_pages: total_pages}
  end

  def apply(
        %__MODULE__{} = state,
        %PagesProcessed{job_id: job_id, batch_id: batch_id, page_count: page_count} = _evt
      ) do
    %__MODULE__{
      state
      | job_id: job_id,
        status: :processing,
        processed_pages: state.processed_pages + page_count,
        active_batch_ids: state.active_batch_ids -- [batch_id]
    }
  end

  def apply(%__MODULE__{} = state, %AllPagesProcessed{job_id: job_id} = _evt) do
    %__MODULE__{
      state
      | job_id: job_id,
        status: :analyzing_results
    }
  end

  # By default skip any problematic events
  def error(error, _command_or_event, _failure_context) do
    Logger.error(fn ->
      "#{__MODULE__} encountered an error: #{inspect(error)}"
    end)

    :skip
  end
end
