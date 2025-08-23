defmodule Crohnjobs.Repo.Migrations.CreateMeasurementdata do
  use Ecto.Migration

  def change do
    create table(:measurementdata) do
      add :date, :date
      add :client_id, references(:clients, on_delete: :delete_all)
      add :measurement_id, references(:measurements, on_delete: :delete_all)
      timestamps(type: :utc_datetime)
    end
  end
end
