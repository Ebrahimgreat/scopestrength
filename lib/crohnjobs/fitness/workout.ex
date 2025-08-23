defmodule Crohnjobs.Fitness.Workout do
  use Ecto.Schema
  import Ecto.Changeset

  schema "workouts" do
    field :name, :string
    field :date , :date
    field :notes , :string
    belongs_to :user, Crohnjobs.Account.User







    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(workout, attrs) do
    workout
    |> cast(attrs, [:name, :date, :notes, :user_id])
    |> validate_required([])
  end
end
