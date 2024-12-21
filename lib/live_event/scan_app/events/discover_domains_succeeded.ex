defmodule LiveEvent.ScanApp.Events.DiscoverDomainsSucceeded do
  @derive Jason.Encoder
  @enforce_keys [:scan_id, :associated_domains]
  defstruct [:scan_id, :associated_domains]
end
