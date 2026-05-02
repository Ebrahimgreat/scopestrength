defmodule Scopestrength.Repo.Migrations.AddNotesAndSetTypeToWorkoutDetails do
  use Ecto.Migration

  def change do
    alter table(:workout_details) do
      add :notes, :text
      add :set_type_id, references(:set_types, on_delete: :nilify_all)
    end

    create index(:workout_details, [:set_type_id])
  end
end
