defmodule Crohnjobs.Trainers.Trainer do
  use Ecto.Schema
  import Ecto.Changeset

  schema "trainers" do
    field :bio, :string
    field :specialization, :string
    belongs_to :user, Crohnjobs.Account.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(trainer, attrs) do
    trainer
    |> cast(attrs, [:bio, :specialization, :user_id])
    |> validate_required([])
  end
end
