defmodule Crohnjobs.Repo.Migrations.CreateProgramme do
  use Ecto.Migration

  def change do
    create table(:programme) do
      add :name, :string
      add :description, :string
      add :trainer_id, references(:trainers, on_delete: :delete_all), null: false
      timestamps(type: :utc_datetime)
    end
  end
end
