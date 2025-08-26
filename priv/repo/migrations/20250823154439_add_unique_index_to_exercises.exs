defmodule Crohnjobs.Repo.Migrations.AddUniqueIndexToExercises do
  use Ecto.Migration

  def change do
    create unique_index(:exercises, [:name])

  end
end
