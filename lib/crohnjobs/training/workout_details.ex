defmodule Crohnjobs.Training.WorkoutDetails do
  use Ecto.Schema
  import Ecto.Changeset

  schema "workout_details" do
    field :reps, :float
    field :weight, :float
    field :set, :integer
    field :side, :string, default: "both"
    field :notes, :string
    belongs_to :exercise, Crohnjobs.Exercises.Exercise
    belongs_to :workout, Crohnjobs.Training.Workout
    belongs_to :set_type, Crohnjobs.Training.SetType
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(workout_details, attrs) do
    workout_details
    |> cast(attrs, [:reps, :weight, :set, :side, :notes, :set_type_id, :workout_id, :exercise_id])
    |> validate_required([])
    |> validate_inclusion(:side, ["both", "left", "right"])
    |> set_default_set_type()
  end

  defp set_default_set_type(changeset) do
    if get_field(changeset, :set_type_id) == nil do
      # Get "Standard" set type ID from database
      standard_type = Crohnjobs.Repo.get_by(Crohnjobs.Training.SetType, name: "Standard")
      if standard_type do
        put_change(changeset, :set_type_id, standard_type.id)
      else
        changeset
      end
    else
      changeset
    end
  end
end
