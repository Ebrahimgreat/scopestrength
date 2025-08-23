defmodule Crohnjobs.Repo.Migrations.AddTrainerIdToExercises do
  use Ecto.Migration

  def change do
    alter table(:exercises) do
      add :trainers_id, references(:trainers, on_delete: :delete_all)
      add :is_custom, :boolean, default: false, null: false
    end

  end
end
