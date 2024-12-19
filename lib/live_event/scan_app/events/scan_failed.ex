defmodule LiveEvent.ScanApp.Events.ScanFailed do
  @derive Jason.Encoder
  defstruct [:scan_id, :error]
end
