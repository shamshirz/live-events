defmodule LiveEvent.ScanApp.Commands.RequestSubdomainDiscovery do
  @derive Jason.Encoder
  defstruct [:scan_id, :domain]
end
