defmodule Crohnjobs.Repo.Migrations.AddWorkoutIdToWorkoutDetails do
  use Ecto.Migration

  def change do
    alter table(:workout_details) do
      add :workout_id, references(:workouts, on_delete: :delete_all)
    end

  end
end
