defmodule LiveEvent.ScanApp.Events.ScanTimedOut do
  @derive Jason.Encoder
  @enforce_keys [:scan_id]
  defstruct [:scan_id]
end
