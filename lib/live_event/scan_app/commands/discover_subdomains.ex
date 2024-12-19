defmodule LiveEvent.ScanApp.Commands.DiscoverSubdomains do
  @derive Jason.Encoder
  defstruct [:scan_id, :domain, :subdomains]
end
