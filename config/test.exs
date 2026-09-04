import Config

config :bcrypt_elixir, :log_rounds, 1

config :scopestrength, Scopestrength.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "scopestrength_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

config :scopestrength, ScopestrengthWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "hNLLVbzdTAZgttT7qZ1sfrVVlLaXq33jBbDgB8NBpjs5gqlsLQQSophOX+dG47cT",
  server: false

config :scopestrength, Scopestrength.Mailer, adapter: Swoosh.Adapters.Test

config :swoosh, :api_client, false

config :logger, level: :warning

config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  enable_expensive_runtime_checks: true

config :scopestrength, Oban, testing: :manual
