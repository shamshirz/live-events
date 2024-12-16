defmodule LiveEvent.App.Events.PagesProcessed do
  @derive [Jason.Encoder]
  defstruct [:job_id, :batch_id, :page_count]
end
