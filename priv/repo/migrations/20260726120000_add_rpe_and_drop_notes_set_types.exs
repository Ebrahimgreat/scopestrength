defmodule Scopestrength.Repo.Migrations.AddRpeAndDropNotesSetTypes do
  use Ecto.Migration

  def up do
    alter table(:workout_details) do
      add :rpe, :float
    end

    alter table(:workout_details) do
      remove :notes
      remove :set_type_id
    end

    drop table(:set_types)
  end

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
