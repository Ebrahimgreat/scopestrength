defmodule Crohnjobs.Programmes.ProgrammeUser do
  use Ecto.Schema
  import Ecto.Changeset

  schema "programmeuser" do


    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(programme_user, attrs) do
    programme_user
    |> cast(attrs, [])
    |> validate_required([])
  end
end
