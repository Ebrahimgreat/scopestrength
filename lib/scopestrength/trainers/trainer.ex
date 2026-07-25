defmodule Scopestrength.Trainers.Trainer do
  use Ecto.Schema
  import Ecto.Changeset

  schema "trainers" do
    field :bio, :string
    field :specialization, :string
    field :is_demo, :boolean
    field :profile_picture_url, :string
    belongs_to :user, Scopestrength.Account.User
    has_many :clients, Scopestrength.Clients.Client
    has_many :invites, Scopestrength.Invites.Invite

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(trainer, attrs) do
    trainer
    |> cast(attrs, [:bio, :specialization, :user_id, :is_demo, :profile_picture_url])
    |> validate_required([])
  end
end
