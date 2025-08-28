defmodule Crohnjobs.Programmes.ProgrammeUser do
  use Ecto.Schema
  import Ecto.Changeset

  schema "programmeuser" do
    field :is_active, :boolean
    belongs_to :programme, Crohnjobs.Programmes.Programme
    belongs_to :client, Crohnjobs.Clients.Client


    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(programme_user, attrs) do
    programme_user
    |> cast(attrs, [:programme_id, :client_id, :is_active])
    |> validate_required([])
  end
end
