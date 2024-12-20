defmodule LiveEvent.ScanApp.Supervisor do
  use Supervisor

  alias LiveEvent.ScanApp

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      # Application
      ScanApp.Application,

      # Process Managers
      ScanApp.ProcessManagers.Scan,

      # Projectors (read model)
      # ScanApp.Projectors.Scan,
      {LiveEvent.ScanApp.Projectors.ScanEctoProjector,
       application: LiveEvent.ScanApp.Application, name: "scan_projection"},

      # Domain Gateway
      LiveEvent.ScanApp.Gateways.DomainGateway
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
