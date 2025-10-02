defmodule Crohnjobs.Fitness.Workout do
  use Ecto.Schema
  import Ecto.Changeset

  schema "workouts" do
    field :name, :string
    field :date, :date
    field :notes, :string
    belongs_to :client, Crohnjobs.Clients.Client
    has_many :workout_detail, Crohnjobs.Fitness.WorkoutDetail

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(workout, attrs) do
    workout
    |> cast(attrs, [:name, :date, :notes, :client_id])
    |> validate_required([])
  end
end
