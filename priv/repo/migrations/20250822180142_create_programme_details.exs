defmodule Crohnjobs.Repo.Migrations.CreateProgrammeDetails do
  use Ecto.Migration

  def change do
    create table(:programme_details) do
      add :set, :string
      add :reps, :string
      add :exercise_id, references(:exercises, on_delete: :delete_all)
      add :programme_template_id, references(:programme_template, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end
  end
end
