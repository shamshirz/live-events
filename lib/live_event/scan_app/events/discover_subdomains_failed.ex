defmodule LiveEvent.ScanApp.Events.DiscoverSubdomainsFailed do
  @derive Jason.Encoder
  defstruct [:scan_id, :domain, :error]
end
