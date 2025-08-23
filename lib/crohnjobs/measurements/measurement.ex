defmodule Crohnjobs.Measurements.Measurement do
  use Ecto.Schema
  import Ecto.Changeset

  schema "measurements" do
    field :name, :string


    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(measurement, attrs) do
    measurement
    |> cast(attrs, [])
    |> validate_required([])
  end
end
