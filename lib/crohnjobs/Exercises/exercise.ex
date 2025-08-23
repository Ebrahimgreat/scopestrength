defmodule Crohnjobs.Exercises.Exercise do
  use Ecto.Schema
  import Ecto.Changeset

  schema "exercises" do
    field :name, :string
    field :type, :string
    field :equipment, :string
    field :is_custom, :boolean
    belongs_to :trainer, Crohnjobs.Trainers.Trainer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(exercise, attrs) do
    exercise
    |> cast(attrs, [:name, :equipment, :type, :trainer_id, :is_custom])
    |> validate_required([:name, :equipment, :type])
  end
end
