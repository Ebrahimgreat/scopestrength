defmodule Crohnjobs.Training.WorkoutDetails do
  use Ecto.Schema
  import Ecto.Changeset

  schema "workout_details" do
    field :reps, :float
    field :weight, :float
    belongs_to :exercise, Crohnjobs.Exercises.Exercise
    belongs_to :workout, Crohnjobs.Fitness.Workout
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(workout_details, attrs) do
    workout_details
    |> cast(attrs, [:reps, :weight, :workout_id, :exercise_id])
    |> validate_required([])
  end
end
