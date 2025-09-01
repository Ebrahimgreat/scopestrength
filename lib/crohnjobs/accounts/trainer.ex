defmodule Crohnjobs.Accounts.Trainer do
  use Ecto.Schema
  import Ecto.Changeset

  schema "trainers" do


    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(trainer, attrs) do
    trainer
    |> cast(attrs, [])
    |> validate_required([])
  end
end
