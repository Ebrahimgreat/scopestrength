defmodule Crohnjobs.Programmes.ProgrammeDetails do
  use Ecto.Schema
  import Ecto.Changeset

  schema "programme_details" do



    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(programme_details, attrs) do
    programme_details
    |> cast(attrs, [])
    |> validate_required([])
  end
end
