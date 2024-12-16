# ---
# Excerpted from "Real-World Event Sourcing",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit https://pragprog.com/titles/khpes for more book information.
# ---
defmodule LiveEvent.App.Router do
  alias LiveEvent.App.Commands.{
    StartJob,
    SetTotalPages,
    ProcessPages,
    CompleteJob
  }

  alias LiveEvent.App.Aggregates.Analysis

  use Commanded.Commands.Router

  identify(Analysis,
    by: :job_id,
    prefix: "job-"
  )

  dispatch([StartJob, SetTotalPages, ProcessPages, CompleteJob], to: Analysis)
end
