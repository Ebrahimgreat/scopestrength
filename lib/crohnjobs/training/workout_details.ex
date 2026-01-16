defmodule Crohnjobs.Training.WorkoutDetails do
  use Ecto.Schema
  import Ecto.Changeset

  schema "workout_details" do
    field :reps, :float
    field :weight, :float
    field :set, :integer
    belongs_to :exercise, Crohnjobs.Exercises.Exercise
    belongs_to :workout_ref, Crohnjobs.Training.Workout, foreign_key: :workout
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(workout_details, attrs) do
    attrs =
      case attrs do
        %{"workout_id" => workout_id} -> Map.put(attrs, "workout", workout_id)
        %{workout_id: workout_id} -> Map.put(attrs, :workout, workout_id)
        _ -> attrs
      end

    workout_details
    |> cast(attrs, [:reps, :weight, :set, :workout, :exercise_id])
    |> validate_required([])
  end
end
