defmodule LiveEvent.ScanApp.Events.DiscoverSubdomainsRequested do
  @derive Jason.Encoder
  defstruct [:scan_id, :domain]
end
