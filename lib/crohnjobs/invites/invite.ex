defmodule Crohnjobs.Invites.Invite do
  use Ecto.Schema
  import Ecto.Changeset

  schema "invites" do
    field :code, :string
    field :email, :string
    field :used, :boolean, default: false
    belongs_to :trainer, Crohnjobs.Trainers.Trainer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(invite, attrs) do
    invite
    |> cast(attrs, [:code, :email, :used, :trainer_id])
    |> validate_required([:code, :email, :trainer_id])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email")
    |> unique_constraint(:code)
  end
end
