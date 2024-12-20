defmodule LiveEvent.ScanApp.Events.DiscoverDomainsFailed do
  @derive Jason.Encoder
  defstruct [:scan_id, :domain, :error]
end
