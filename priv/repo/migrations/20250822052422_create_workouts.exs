defmodule Crohnjobs.Repo.Migrations.CreateWorkouts do
  use Ecto.Migration

  def change do
    create table(:workouts) do
      add :name, :string
      add :date, :date
      add :notes, :string
      add :client_id, references(:clients, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end
  end
end
