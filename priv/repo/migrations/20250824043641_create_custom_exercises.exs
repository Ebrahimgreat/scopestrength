defmodule Crohnjobs.Repo.Migrations.CreateCustomExercises do
  use Ecto.Migration

  def change do
    create table(:custom_exercises) do
      add :name, :string
      add :type, :string
      add :equipment, :string
      add :trainer_id, references(:trainers, on_delete: :delete_all)



      timestamps(type: :utc_datetime)
    end
    create unique_index(:custom_exercises, [:name])

  end
end
