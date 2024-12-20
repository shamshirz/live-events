defmodule LiveEvent.ScanApp.Commands.DiscoverSubdomainsRequest do
  @derive Jason.Encoder
  defstruct [:scan_id, :domain]
end
