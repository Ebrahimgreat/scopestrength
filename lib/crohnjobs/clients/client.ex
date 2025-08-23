defmodule Crohnjobs.Clients.Client do
  use Ecto.Schema
  import Ecto.Changeset

  schema "clients" do

    field :age, :integer
    field :height, :decimal
    field :notes, :string
    field :sex, :string
    belongs_to :user, Crohnjobs.Account.User
    belongs_to :trainers, Crohnjobs.Trainers.Trainer



    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(client, attrs) do
    client
    |> cast(attrs, [ :age, :height, :notes, :sex, :user_id, :trainers_id])
    |> validate_required([])
  end
end
