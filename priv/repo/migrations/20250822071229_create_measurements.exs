defmodule Crohnjobs.Repo.Migrations.CreateMeasurements do
  use Ecto.Migration

  def change do
    create table(:measurements) do
      add :name, :string


      timestamps(type: :utc_datetime)
    end
  end
end
