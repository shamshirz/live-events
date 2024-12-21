defmodule LiveEvent.ScanApp.Events.DiscoverSubdomainsSucceeded do
  @derive Jason.Encoder
  @enforce_keys [:scan_id, :domain, :subdomains]
  defstruct [:scan_id, :domain, :subdomains]
end
