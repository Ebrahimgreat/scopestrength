defmodule Crohnjobs.Repo.Migrations.CreateWorkouts do
  use Ecto.Migration

  def change do
    create table(:workouts) do
      add :client_id, references(:clients, on_delete: :delete_all)
      add :date, :utc_datetime
      add :name, :string
      timestamps(type: :utc_datetime)
    end
  end
end
