defmodule LiveEvent.ScanApp.Commands.StartScan do
  @derive Jason.Encoder
  defstruct [:scan_id, :domain]
end
