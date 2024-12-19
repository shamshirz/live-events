defmodule LiveEvent.ScanApp.Events.DiscoveredSubdomains do
  @derive Jason.Encoder
  defstruct [:scan_id, :domain, :subdomains]
end
