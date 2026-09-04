defmodule Scopestrength.Repo.Migrations.AddStatusToClientProgression do
  use Ecto.Migration

  def change do
    alter table(:client_progressions) do
      add :status, :string, default: "hold"
    end

  end
end
