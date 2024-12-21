defmodule LiveEvent.ScanApp.Events.DiscoverSubdomainsRequested do
  @derive Jason.Encoder
  @enforce_keys [:scan_id, :domain]
  defstruct [:scan_id, :domain]
end
