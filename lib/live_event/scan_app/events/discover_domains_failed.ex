defmodule LiveEvent.ScanApp.Events.DiscoverDomainsFailed do
  @derive Jason.Encoder
  @enforce_keys [:scan_id, :domain, :error]
  defstruct [:scan_id, :domain, :error]
end
