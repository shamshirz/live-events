defmodule LiveEvent.ScanApp.Commands.DiscoverDomainsSuccess do
  @derive Jason.Encoder
  defstruct [:scan_id, :associated_domains]
end
