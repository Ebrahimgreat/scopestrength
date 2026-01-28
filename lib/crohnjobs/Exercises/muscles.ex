defmodule Crohnjobs.Exercises.Muscles do
  use Ecto.Schema
  import Ecto.Changeset

  schema "muscles" do
    field :name, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(muscles, attrs) do
    muscles
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
