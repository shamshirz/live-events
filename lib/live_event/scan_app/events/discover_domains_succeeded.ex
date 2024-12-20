defmodule LiveEvent.ScanApp.Events.DiscoverDomainsSucceeded do
  @derive Jason.Encoder
  defstruct [:scan_id, :associated_domains]
end
