defmodule Crohnjobs.Measurements.MeasurementData do
  use Ecto.Schema
  import Ecto.Changeset

  schema "measurementdata" do
    field :value, :decimal
    belongs_to :measurement_id, Crohnjobs.Measurements.Measurement
    belongs_to :client_id, CrohnJobs.Clients.Client


    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(measurement_data, attrs) do
    measurement_data
    |> cast(attrs, [])
    |> validate_required([])
  end
end
