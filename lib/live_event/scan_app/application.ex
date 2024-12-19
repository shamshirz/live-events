defmodule LiveEvent.ScanApp.Application do
  require Logger

  use Commanded.Application, otp_app: :live_event

  router(LiveEvent.ScanApp.Router)

  # Provide / Override runtime configuration
  def init(config) do
    Logger.info("Starting LiveEvent Scan Event Sourcing App")
    {:ok, config}
  end
end
