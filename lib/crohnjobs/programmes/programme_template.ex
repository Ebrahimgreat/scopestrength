defmodule Crohnjobs.Programmes.ProgrammeTemplate do
  use Ecto.Schema
  import Ecto.Changeset

  schema "programme_template" do
    field :name, :string
    belongs_to :programmes, Crohnjobs.Programmes


    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(programme_template, attrs) do
    programme_template
    |> cast(attrs, [:name, :programme_id ])
    |> validate_required([])
  end
end
