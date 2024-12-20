import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :live_event, LiveEvent.Repo,
  database: Path.expand("../live_event_test.db", __DIR__),
  pool_size: 5,
  pool: Ecto.Adapters.SQL.Sandbox

config :live_event, LiveEvent.ScanApp.Application,
  event_store: [
    adapter: Commanded.EventStore.Adapters.InMemory,
    serializer: Commanded.Serialization.JsonSerializer
  ],
  pubsub: :local,
  registry: :local

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :live_event, LiveEventWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "2LabnmJnQ37g8PczWSCz95eYW2XwdzMSTUfzLSNPhX88sf3T3KZcbIub2ydA1tS3",
  server: false

# In test we don't send emails
config :live_event, LiveEvent.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
