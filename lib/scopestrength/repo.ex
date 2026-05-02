defmodule Scopestrength.Repo do
  use Ecto.Repo,
    otp_app: :scopestrength,
    adapter: Ecto.Adapters.Postgres
end
