defmodule Scopestrength.Exercises.Exercise do
  use Ecto.Schema
  import Ecto.Changeset

  schema "exercises" do
    field :name, :string
    field :is_custom, :boolean, default: false
    field :is_unilateral, :boolean, default: false
    belongs_to :muscle, Scopestrength.Exercises.Muscles
    belongs_to :equipment, Scopestrength.Exercises.Equipment
    belongs_to :user, Scopestrength.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(exercise, attrs) do
    exercise
    |> cast(attrs, [:name, :muscle_id, :equipment_id, :is_custom, :is_unilateral, :user_id])
    |> validate_required([:name, :muscle_id, :equipment_id])
    |> unique_constraint(:name)
  end
end
