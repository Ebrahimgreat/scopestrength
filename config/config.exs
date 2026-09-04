
import Config

config :scopestrength, Oban,
  repo: Scopestrength.Repo,
  plugins: [

    Oban.Plugins.Cron
  ],
  queues: [default: 10, events: 50]

config :scopestrength,
  ecto_repos: [Scopestrength.Repo],
  generators: [timestamp_type: :utc_datetime]

config :scopestrength, ScopestrengthWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: ScopestrengthWeb.ErrorHTML, json: ScopestrengthWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Scopestrength.PubSub,
  live_view: [signing_salt: "VljeHh3S"]

config :scopestrength, Scopestrength.Mailer, adapter: Swoosh.Adapters.Local

config :esbuild,
  version: "0.17.11",
  scopestrength: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :tailwind,
  version: "3.4.3",
  scopestrength: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
