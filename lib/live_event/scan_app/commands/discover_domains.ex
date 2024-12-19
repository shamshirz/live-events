defmodule LiveEvent.ScanApp.Commands.DiscoverDomains do
  @derive Jason.Encoder
  defstruct [:scan_id, :domain, :associated_domains]
end
