defmodule LiveEvent.App.Events.TotalPagesSet do
  @derive [Jason.Encoder]
  defstruct [:job_id, :total_pages]
end
