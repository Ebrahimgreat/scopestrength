defmodule Crohnjobs.ClientNote.ClientNotes do
  use Ecto.Schema
  import Ecto.Changeset

  schema "client_notes" do
    field :date, :date
    field :notes, :string
    belongs_to :client, Crohnjobs.Clients.Client


    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(client_notes, attrs) do
    client_notes
    |> cast(attrs, [:date, :client_id, :notes])
    |> validate_required([])
  end
end
