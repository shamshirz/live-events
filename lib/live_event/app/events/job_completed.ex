defmodule LiveEvent.App.Events.JobCompleted do
  @derive [Jason.Encoder]
  defstruct [:job_id]
end
