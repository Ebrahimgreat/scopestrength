defmodule Crohnjobs.Fitness.WorkoutDetail do
  use Ecto.Schema
  import Ecto.Changeset

  schema "workout_details" do
    field :reps, :integer
    field :set , :integer
    field :weight, :decimal
    belongs_to :exercise, Crohnjobs.Workout.Exercise
    belongs_to :workout, Crohnjobs.Fitness.Workout

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(workout_detail, attrs) do
    workout_detail
    |> cast(attrs, [])
    |> validate_required([])
  end
end
