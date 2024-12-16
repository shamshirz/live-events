defmodule LiveEvent.DocumentProcessingGateway do
  @doc """
  Request total pages for a given document_id and associate result with given job_id.
  """
  import LiveEvent.App.Application

  def request_total_pages(job_id) do
    IO.puts("#{job_id}: request_total_pages")
    # Make external API call asynchronously (e.g., using a Task, Oban job, or GenServer).
    # Once the external system responds with total_pages, you "inject" it back in:
    # MyApp.CommandedApp.dispatch(%MyApp.Jobs.Commands.SetTotalPages{job_id: job_id, total_pages: total_pages})
    # For now, simulate an async response:
    Task.start(fn ->
      # Simulate delay
      Process.sleep(2000)
      # pretend we got this from external system
      total_pages = min(:rand.uniform(25), :rand.uniform(50))

      dispatch(%LiveEvent.App.Commands.SetTotalPages{
        job_id: job_id,
        total_pages: total_pages
      })
    end)

    :ok
  end

  @doc """
  Request processing of a single page (optional, if you are orchestrating pages).
  """
  def process_pages(job_id, batch_id, page_count) do
    IO.puts("#{job_id}:#{batch_id}: process_pages - #{page_count}")
    # Similar async logic, eventually calls the injector to dispatch PageProcessed
    Task.start(fn ->
      # simulate work
      Process.sleep(1000)

      dispatch(%LiveEvent.App.Commands.ProcessPages{
        job_id: job_id,
        batch_id: batch_id,
        page_count: page_count
      })
    end)

    :ok
  end

  def complete_job(job_id) do
    IO.puts("#{job_id}: complete_job")
    Process.sleep(:rand.uniform(10) * 1000)
    dispatch(%LiveEvent.App.Commands.CompleteJob{job_id: job_id})
  end
end
