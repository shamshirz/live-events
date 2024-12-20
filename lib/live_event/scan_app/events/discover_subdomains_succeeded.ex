defmodule LiveEvent.ScanApp.Events.DiscoverSubdomainsSucceeded do
  @derive Jason.Encoder
  defstruct [:scan_id, :domain, :subdomains]
end
