defmodule Crohnjobs.Repo.Migrations.CreateEquipment do
  use Ecto.Migration

  def change do
    create table(:equipment) do
      add :name, :string

      timestamps(type: :utc_datetime)
    end
  end
end
