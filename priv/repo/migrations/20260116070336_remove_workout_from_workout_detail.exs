defmodule Crohnjobs.Repo.Migrations.RemoveWorkoutFromWorkoutDetail do
  use Ecto.Migration

  def change do
    alter table(:workout_details) do
      remove :workout

    end
  end
end
