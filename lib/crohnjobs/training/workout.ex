defmodule Crohnjobs.Training.Workout do
  use Ecto.Schema
  import Ecto.Changeset

  schema "workouts" do
    field :name, :string
    field :date, :utc_datetime
    belongs_to :client, Crohnjobs.Clients.Client

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(workout, attrs) do
    workout
    |> cast(attrs, [:name, :date, :client_id])
    |> validate_required([])
  end
end
