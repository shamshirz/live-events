defmodule LiveEvent.ScanApp.Events.DiscoveredDomains do
  @derive Jason.Encoder
  defstruct [:scan_id, :domains]
end
