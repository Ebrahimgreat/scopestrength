import Config

env_path = Path.expand("../.env", __DIR__)
if config_env() == :dev and File.exists?(env_path) do
  File.read!(env_path)
  |> String.split("\n", trim: true)
  |> Enum.reject(&String.starts_with?(&1, "#"))
  |> Enum.each(fn line ->
    case String.split(line, "=", parts: 2) do
      [key, value] -> System.put_env(String.trim(key), String.trim(value))
      _ -> :ok
    end
  end)
end


if System.get_env("PHX_SERVER") do
  config :scopestrength, ScopestrengthWeb.Endpoint, server: true
end

# Public self-registration (/users/register) is on by default so a fresh
# self-hosted install can create its first account. Set
# REGISTRATION_ENABLED=false to close it once your accounts exist and you
# add clients from the trainer dashboard instead -- the demo and login
# pages stay reachable either way.
config :scopestrength, :registration_enabled, System.get_env("REGISTRATION_ENABLED") != "false"

if bucket = System.get_env("S3_BUCKET") do
  config :scopestrength, :storage,
    adapter: Scopestrength.Storage.S3,
    bucket: bucket

  missing = Enum.filter(~w(S3_ACCESS_KEY_ID S3_SECRET_ACCESS_KEY), &(System.get_env(&1) in [nil, ""]))

  if missing != [] do
    raise """
    S3_BUCKET is set, so uploads go to object storage, but #{Enum.join(missing, " and ")} #{if length(missing) == 1, do: "is", else: "are"} missing.

    Set them, or unset S3_BUCKET to store uploads on local disk instead.
    """
  end

  config :ex_aws,
    access_key_id: System.fetch_env!("S3_ACCESS_KEY_ID"),
    secret_access_key: System.fetch_env!("S3_SECRET_ACCESS_KEY"),
    region: System.get_env("S3_REGION") || "us-east-1",
    json_codec: Jason

  if host = System.get_env("S3_HOST") do
    config :ex_aws, :s3,
      scheme: System.get_env("S3_SCHEME") || "https://",
      host: host,
      port: String.to_integer(System.get_env("S3_PORT") || "443")
  end
else
  config :scopestrength, :storage, adapter: Scopestrength.Storage.Local
end

mail_from =
  case System.get_env("MAIL_FROM") do
    nil ->
      {"ScopeStrength", "noreply@localhost"}

    from ->
      case Regex.run(~r/^\s*(.*?)\s*<([^>]+)>\s*$/, from) do
        [_, "", address] -> {"ScopeStrength", address}
        [_, name, address] -> {name, address}
        nil -> {"ScopeStrength", String.trim(from)}
      end
  end

config :scopestrength, :mail_from, mail_from

mailer_adapter = System.get_env("MAILER_ADAPTER")

api_key = fn ->
  System.get_env("MAILER_API_KEY") ||
    raise "MAILER_ADAPTER=#{mailer_adapter} needs MAILER_API_KEY to be set"
end

case mailer_adapter do
  adapter when adapter in [nil, "", "local"] ->
    if config_env() == :prod and adapter != "local" do
      IO.puts(:stderr, """
      [warning] MAILER_ADAPTER is not set, so ScopeStrength cannot send email.
      Password reset and account confirmation emails will be dropped.
      Set MAILER_ADAPTER (smtp, resend, sendgrid, postmark or mailgun) to enable them.
      """)
    end

    config :scopestrength, Scopestrength.Mailer, adapter: Swoosh.Adapters.Local

  "smtp" ->
    relay = System.get_env("SMTP_HOST") || raise "MAILER_ADAPTER=smtp needs SMTP_HOST to be set"
    port = String.to_integer(System.get_env("SMTP_PORT") || "587")
    username = System.get_env("SMTP_USERNAME")
    password = System.get_env("SMTP_PASSWORD")

    config :scopestrength, Scopestrength.Mailer,
      adapter: Swoosh.Adapters.SMTP,
      relay: relay,
      port: port,
      username: username,
      password: password,
      auth: if(username, do: :always, else: :never),
      ssl: port == 465,
      tls: if(port == 465, do: :never, else: :if_available),
      tls_options: [verify: :verify_peer, cacerts: :public_key.cacerts_get(), server_name_indication: String.to_charlist(relay), depth: 3],
      retries: 2

  "resend" ->
    config :scopestrength, Scopestrength.Mailer, adapter: Swoosh.Adapters.Resend, api_key: api_key.()

  "sendgrid" ->
    config :scopestrength, Scopestrength.Mailer, adapter: Swoosh.Adapters.Sendgrid, api_key: api_key.()

  "postmark" ->
    config :scopestrength, Scopestrength.Mailer, adapter: Swoosh.Adapters.Postmark, api_key: api_key.()

  "mailgun" ->
    domain = System.get_env("MAILGUN_DOMAIN") || raise "MAILER_ADAPTER=mailgun needs MAILGUN_DOMAIN to be set"

    config :scopestrength, Scopestrength.Mailer,
      adapter: Swoosh.Adapters.Mailgun,
      api_key: api_key.(),
      domain: domain

  other ->
    raise "unknown MAILER_ADAPTER #{inspect(other)}; expected smtp, resend, sendgrid, postmark, mailgun or local"
end

if mailer_adapter in ["resend", "sendgrid", "postmark", "mailgun"] do
  config :swoosh, api_client: Swoosh.ApiClient.Finch, finch_name: Scopestrength.Finch
end

if config_env() == :prod do
  host =
    System.get_env("PHX_HOST") ||
      raise """
      environment variable PHX_HOST is missing.
      This is the public hostname the app is served from, e.g. app.scopestrength.com
      """

  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  config :scopestrength, Scopestrength.Repo,
    url: database_url,
    ssl: [verify: :verify_none],
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "2")

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  port = String.to_integer(System.get_env("PORT") || "4000")

  config :scopestrength, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :scopestrength, ScopestrengthWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    check_origin: ["https://#{host}"],
    force_ssl: [rewrite_on: [:x_forwarded_proto]],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base


end
