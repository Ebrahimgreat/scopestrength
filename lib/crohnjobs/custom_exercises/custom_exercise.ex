defmodule Crohnjobs.CustomExercises.CustomExercise do
  use Ecto.Schema
  import Ecto.Changeset

  schema "custom_exercises" do
    field :name, :string
    field :type, :string
    field :equipment, :string
    belongs_to :trainer, Crohnjobs.Trainers.Trainer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(custom_exercise, attrs) do
    custom_exercise
    |> cast(attrs, [ :name, :type, :type, :equipment, :trainer_id])
    |> unique_constraint(:name)

    |> validate_required([])
  end
end
