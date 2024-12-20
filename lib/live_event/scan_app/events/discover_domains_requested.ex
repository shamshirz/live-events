defmodule LiveEvent.ScanApp.Events.DiscoverDomainsRequested do
  @derive Jason.Encoder
  defstruct [:scan_id, :domain]
end
