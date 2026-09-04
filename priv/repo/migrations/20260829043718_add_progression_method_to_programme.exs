defmodule Scopestrength.Repo.Migrations.AddProgressionMethodToProgramme do
  use Ecto.Migration

  def change do
    alter table(:programme) do
      add :progression_method, :string
    end

  end
end
