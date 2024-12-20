defmodule LiveEvent.ScanApp.Commands.DiscoverDomainsFail do
  @derive Jason.Encoder
  defstruct [:scan_id, :error]
end
