defmodule LiveEvent.ScanApp.Events.ScanCompleted do
  @derive Jason.Encoder
  defstruct [:scan_id, :score, :domains, :subdomains, :completed_at]
end
