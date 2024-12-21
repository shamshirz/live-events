defmodule LiveEvent.ScanApp.Events.ScanFailed do
  @derive Jason.Encoder
  @enforce_keys [:scan_id, :error]
  defstruct [:scan_id, :error]
end
