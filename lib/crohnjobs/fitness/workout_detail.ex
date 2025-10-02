defmodule Crohnjobs.Fitness.WorkoutDetail do
  use Ecto.Schema
  import Ecto.Changeset

  schema "workout_details" do
    field :set, :integer
    field :reps, :integer
    field :weight, :float
    field :rir, :integer
    belongs_to :exercise, Crohnjobs.Exercises.Exercise
    belongs_to :workout, Crohnjobs.Fitness.Workout


    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(workout_detaial, attrs) do
    workout_detaial
    |> cast(attrs, [:set, :reps, :rir, :set, :workout_id, :exercise_id])
    |> validate_required([])
  end
end
