defmodule LiveEvent.ScanApp.Events.DiscoverDomainsRequested do
  @derive Jason.Encoder
  @enforce_keys [:scan_id, :domain]
  defstruct [:scan_id, :domain]
end
