defmodule LiveEvent.App.Supervisor do
  use Supervisor

  alias LiveEvent.App

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      # Application
      App.Application,

      # Process Managers
      App.ProcessManagers.Analysis,

      # Projectors (read model)
      App.Projectors.Analysis
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
