defmodule Crohnjobs.Repo.Migrations.DropWorkoutAndWorkoutDetails do
  use Ecto.Migration

  def change do
    drop table(:workout_details)
    drop table(:workouts)

  end
end
