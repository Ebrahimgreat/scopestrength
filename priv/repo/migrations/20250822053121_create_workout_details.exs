defmodule Crohnjobs.Repo.Migrations.CreateWorkoutDetails do
  use Ecto.Migration

  def change do
    create table(:workout_details) do
      add :exercise_id, references(:exercises, on_delete: :delete_all)
      add :rir, :integer
      add :reps, :integer
      add :weight, :decimal, precision: 8, scale: 2
      add :workout_id, references(:workouts, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end
  end
end
