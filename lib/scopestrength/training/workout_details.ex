defmodule Scopestrength.Training.WorkoutDetails do
  use Ecto.Schema
  import Ecto.Changeset

  schema "workout_details" do
    field :reps, :float
    field :weight, :float
    field :set, :integer
    field :rir, :float, default: 0.0
    field :rpe, :float
    field :side, :string, default: "both"
    belongs_to :exercise, Scopestrength.Exercises.Exercise
    belongs_to :workout, Scopestrength.Training.Workout
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(workout_details, attrs) do
    workout_details
    |> cast(attrs, [:reps, :weight, :set, :side, :workout_id, :rir, :rpe, :exercise_id])
    |> validate_required([])
    |> validate_inclusion(:side, ["both", "left", "right"])
    |> validate_number(:rpe, greater_than_or_equal_to: 1, less_than_or_equal_to: 10)
  end
end
