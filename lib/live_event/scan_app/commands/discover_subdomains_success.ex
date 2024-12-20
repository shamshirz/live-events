defmodule LiveEvent.ScanApp.Commands.DiscoverSubdomainsSuccess do
  @derive Jason.Encoder
  defstruct [:scan_id, :domain, :subdomains]
end
