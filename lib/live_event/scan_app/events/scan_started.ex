defmodule LiveEvent.ScanApp.Events.ScanStarted do
  @derive Jason.Encoder
  defstruct [:scan_id, :domain, :started_at]
end
