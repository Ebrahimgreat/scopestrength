defmodule Scopestrength.Exercises.ExerciseMuscleContribution do
  use Ecto.Schema
  import Ecto.Changeset

  schema "exercise_muscle_contribution" do
    belongs_to :muscle, Scopestrength.Exercises.Muscles
    belongs_to :exercise, Scopestrength.Exercises.Exercise
    field :role, :string
    field :multiplier, :float
    belongs_to :trainer, Scopestrength.Accounts.Trainer



    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(exercise_muscle_contribution, attrs) do
    exercise_muscle_contribution
    |> cast(attrs, [:muscle_id, :role, :multiplier, :trainer_id, :exercise_id])
    |> validate_required([:muscle_id, :role, :multiplier, :exercise_id])
  end
end
