defmodule Scopestrength.Training.SetType do
  use Ecto.Schema
  import Ecto.Changeset

  schema "set_types" do
    field :name, :string
    field :description, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(set_type, attrs) do
    set_type
    |> cast(attrs, [:name, :description])
    |> validate_required([:name, :description])
  end
end
