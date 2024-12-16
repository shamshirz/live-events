defmodule LiveEvent.App.Events.JobStarted do
  @derive [Jason.Encoder]
  defstruct [:job_id]
end
