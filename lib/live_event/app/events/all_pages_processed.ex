defmodule LiveEvent.App.Events.AllPagesProcessed do
  @derive [Jason.Encoder]
  defstruct [:job_id]
end
