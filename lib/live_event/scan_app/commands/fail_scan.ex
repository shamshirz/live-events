defmodule LiveEvent.ScanApp.Commands.FailScan do
  @derive Jason.Encoder
  defstruct [:scan_id, :error]
end
