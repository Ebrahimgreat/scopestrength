defmodule Crohnjobs.Exercises.Equipment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "equipment" do
    field :name, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(equipment, attrs) do
    equipment
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
