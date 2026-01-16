defmodule Crohnjobs.Exercises.Exercise do
  use Ecto.Schema
  import Ecto.Changeset

  schema "exercises" do
    field :name, :string
    field :type, :string
    field :equipment, :string
    field :is_custom, :boolean, default: false
    belongs_to :user, Crohnjobs.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(exercise, attrs) do
    exercise
    |> cast(attrs, [:name, :equipment, :type, :is_custom, :user_id])
    |> validate_required([:name, :equipment, :type])
    |> unique_constraint(:name)
  end
end
