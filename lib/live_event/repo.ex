defmodule LiveEvent.Repo do
  use Ecto.Repo,
    otp_app: :live_event,
    adapter: Ecto.Adapters.SQLite3
end
