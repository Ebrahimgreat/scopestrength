defmodule Crohnjobs.Repo.Migrations.CreateCustomExercises do
  use Ecto.Migration

  def change do
    create table(:custom_exercises) do
      add  :name, :string
      add :equipment, :string
      add :type, :string
      add :trainer_id, references(:trainers, on_delete: :delete_all), null: false




      timestamps(type: :utc_datetime)
    end
  end
end
