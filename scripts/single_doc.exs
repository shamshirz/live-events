# iex -S mix run scripts/single_doc.exs

alias LiveEvent.App.Aggregates.Analysis
alias LiveEvent.App.Commands
import LiveEvent.App.Application

job_id = "123"
IO.puts "New job #{job_id}"

dispatch(%Commands.StartJob{job_id: job_id})
# dispatch(%Commands.SetTotalPages{job_id: job_id, total_pages: 45})
