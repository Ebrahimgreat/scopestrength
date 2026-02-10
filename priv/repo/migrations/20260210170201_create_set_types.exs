defmodule Crohnjobs.Repo.Migrations.CreateSetTypes do
  use Ecto.Migration

  def change do
    create table(:set_types) do
      add :name, :string
      add :description, :text

      timestamps(type: :utc_datetime)
    end
  end
end
