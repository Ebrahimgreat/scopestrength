defmodule Crohnjobs.Strength.StrengthProgress do
  use Ecto.Schema
  import Ecto.Changeset

  schema "strength_progress" do
    field :date, :date
    field :repRange, :string
    field :weight, :float

    belongs_to :client, Crohnjobs.Accounts.Client
    belongs_to :exercise, Crohnjobs.Exercises.Exercise
    belongs_to :custom_exercise, Crohnjobs.Exercises.CustomExercise

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(strength_progress, attrs) do
    strength_progress
    |> cast(attrs, [:date, :client_id, :exercise_id, :custom_exercise_id, :repRange, :weight])
    |> validate_required([:date, :client_id])
    |> validate_one_of_exercise()
  end

  # Custom validation to ensure at least one exercise is present
  defp validate_one_of_exercise(changeset) do
    exercise_id = get_field(changeset, :exercise_id)
    custom_exercise_id = get_field(changeset, :custom_exercise_id)

    if is_nil(exercise_id) and is_nil(custom_exercise_id) do
      add_error(changeset, :base, "Either exercise_id or custom_exercise_id must be present")
    else
      changeset
    end
  end
end
