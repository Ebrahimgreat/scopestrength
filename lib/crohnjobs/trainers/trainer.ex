defmodule Crohnjobs.Trainers.Trainer do
  use Ecto.Schema
  import Ecto.Changeset

  schema "trainers" do
    field :bio, :string
    field :specialization, :string
    belongs_to :user, Crohnjobs.Account.User
    has_many :clients, Crohnjobs.Clients.Client
    has_many :programmes, Crohnjobs.Programmes.Programme
    has_many :invites, Crohnjobs.Invites.Invite

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(trainer, attrs) do
    trainer
    |> cast(attrs, [:bio, :specialization, :user_id])
    |> validate_required([])
  end
end
