defmodule Crohnjobs.Exercises.Exercise do
  use Ecto.Schema
  import Ecto.Changeset

  schema "exercises" do
    field :name, :string
    field :type, :string
    field :equipment, :string


    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(exercise, attrs) do
    exercise
    |> cast(attrs, [:name, :equipment, :type])
    |> unique_constraint(:name)
    |> validate_required([:name, :equipment, :type])
  end
end
