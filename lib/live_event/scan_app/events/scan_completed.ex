defmodule LiveEvent.ScanApp.Events.ScanCompleted do
  @derive Jason.Encoder
  @enforce_keys [:scan_id, :score, :domains, :subdomains, :completed_at]
  defstruct [:scan_id, :score, :domains, :subdomains, :completed_at]
end
