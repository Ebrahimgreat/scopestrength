defmodule Scopestrength.ClientRequests.ClientRequest do
  use Ecto.Schema
  import Ecto.Changeset

  schema "client_requests" do
    field  :status, :string
    field :message, :string
    belongs_to :client, Scopestrength.Clients.Client
    belongs_to :trainer, Scopestrength.Trainers.Trainer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(client_request, attrs) do
    client_request
    |> cast(attrs, [:status, :message, :client_id, :trainer_id])
    |> validate_required([:client_id, :trainer_id])
  end
end
