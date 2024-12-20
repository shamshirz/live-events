defmodule LiveEvent.ScanApp.Commands.DiscoverSubdomainsFail do
  @derive Jason.Encoder
  defstruct [:scan_id, :domain, :error]
end
