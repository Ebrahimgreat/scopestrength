defmodule Crohnjobs.Repo.Migrations.DropCustomExercisesTable do
  use Ecto.Migration

  def change do
    drop table(:custom_exercises)

  end
end
