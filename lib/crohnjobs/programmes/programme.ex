defmodule Crohnjobs.Programmes.Programme do
  use Ecto.Schema
  import Ecto.Changeset

  schema "programme" do
 field :name, :string
 field :description, :string
 belongs_to :trainer, CrohnJobs.Trainer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(programme, attrs) do
    programme
    |> cast(attrs, [:name, :description, :trainer_id])
    |> validate_required([])
  end
end
