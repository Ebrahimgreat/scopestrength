defmodule Crohnjobs.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Run migrations automatically in production
    try do
      Crohnjobs.Release.migrate()
    rescue
      e ->
        require Logger
        Logger.error("Auto-migration failed: #{inspect(e)}")
        :ok
    end

    children = [
      CrohnjobsWeb.Telemetry,
      Crohnjobs.Repo,
      {Oban, Application.fetch_env!(:crohnjobs, Oban)},
      {Phoenix.PubSub, name: Crohnjobs.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Crohnjobs.Finch},
      # Start a worker by calling: Crohnjobs.Worker.start_link(arg)
      # {Crohnjobs.Worker, arg},
      # Start to serve requests, typically the last entry
      CrohnjobsWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Crohnjobs.Supervisor]
    {:ok, pid} = Supervisor.start_link(children, opts)

    # Auto-seed if database is empty (only runs once)
    try do
      if Crohnjobs.Repo.aggregate(Crohnjobs.Account.User, :count) == 0 do
        require Logger
        Logger.info("Database is empty, running seeds...")
        seed_file = Application.app_dir(:crohnjobs, "priv/repo/seeds.exs")

        if File.exists?(seed_file) do
          Code.eval_file(seed_file)
          Logger.info("Seeds completed successfully!")
        end
      end
    rescue
      e ->
        require Logger
        Logger.error("Auto-seed failed: #{inspect(e)}")
    end

    {:ok, pid}
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CrohnjobsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
