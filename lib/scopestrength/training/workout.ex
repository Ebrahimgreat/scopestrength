defmodule Scopestrength.Training.Workout do
  use Ecto.Schema
  import Ecto.Changeset

  schema "workouts" do
    field :name, :string
    field :date, :utc_datetime
    field :notes, :string
    belongs_to :client, Scopestrength.Clients.Client
    has_many :workoutDetails,Scopestrength.Training.WorkoutDetails

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(workout, attrs) do
    workout
    |> cast(attrs, [:name, :date, :client_id, :notes])
    |> validate_required([])
  end
end
