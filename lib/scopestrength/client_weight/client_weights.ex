defmodule Scopestrength.ClientWeight.ClientWeights do
  use Ecto.Schema
  import Ecto.Changeset

  schema "client_weight" do
    field :date, :date
    field :weight, :decimal
    belongs_to :client, Scopestrength.Clients.Client

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(client_weight, attrs) do
    client_weight
    |> cast(attrs, [:date, :client_id, :weight])
    |> validate_required([])
    |> validate_number(:weight, greater_than: 0)
  end
end
