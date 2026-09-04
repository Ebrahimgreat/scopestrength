import Config

config :scopestrength, Scopestrength.Repo,
  username: "postgres",
  password: "",
  hostname: "localhost",
  database: "scopestrength_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :scopestrength, ScopestrengthWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "NsDXsLAhKfXO4jhSJKQOsCPgQWEwsoNX8gIMjESC596LyRWra+9e/iQbgWGgIE+X",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:scopestrength, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:scopestrength, ~w(--watch)]}
  ]


config :scopestrength, ScopestrengthWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/scopestrength_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

config :scopestrength, dev_routes: true

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20

config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  debug_heex_annotations: true,
  debug_attributes: true,
  enable_expensive_runtime_checks: true

config :swoosh, :api_client, false
