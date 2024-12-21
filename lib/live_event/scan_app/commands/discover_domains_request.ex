defmodule LiveEvent.ScanApp.Commands.DiscoverDomainsRequest do
  @derive Jason.Encoder
  defstruct [:scan_id, :domain]
end
