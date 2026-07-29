defmodule Scopestrength.Repo.Migrations.AddRpeAndDropNotesSetTypes do
  use Ecto.Migration

  def up do
    alter table(:workout_details) do
      add :rpe, :float
    end

    # The set type and per-set notes fields were removed from the product:
    # set types were rarely anything but "Standard", and notes were arbitrary.
    # Dropping the FK column before the table it references.
    alter table(:workout_details) do
      remove :notes
      remove :set_type_id
    end

    drop table(:set_types)
  end

  # Restores the original column types and FK behaviour from
  # CreateSetTypes / AddNotesAndSetTypeToWorkoutDetails. Note this brings back
  # the structure only — the dropped rows are not recoverable.
  def down do
    create table(:set_types) do
      add :name, :string
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    alter table(:workout_details) do
      add :notes, :text
      add :set_type_id, references(:set_types, on_delete: :nilify_all)
      remove :rpe
    end

    create index(:workout_details, [:set_type_id])
  end
end
