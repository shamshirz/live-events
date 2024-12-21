defmodule LiveEvent.ScanApp.Events.ScanStarted do
  @derive Jason.Encoder
  @enforce_keys [:scan_id, :domain]
  defstruct [:scan_id, :domain, :started_at]
end
