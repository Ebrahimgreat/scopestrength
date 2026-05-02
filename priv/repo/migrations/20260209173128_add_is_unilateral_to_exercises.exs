defmodule Scopestrength.Repo.Migrations.AddIsUnilateralToExercises do
  use Ecto.Migration

  def change do
    alter table(:exercises) do
      add :is_unilateral, :boolean, default: false, null: false
    end
  end
end
