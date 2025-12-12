defmodule Crohnjobs.Repo.Migrations.CreateStrengthProgress do
  use Ecto.Migration

  def change do
    create table(:strength_progress) do
      add :date, :date
      add :client_id, references(:clients, on_delete: :delete_all)
      add :exercise_id, references(:exercises, on_delete: :nilify_all)
      add :custom_exercise_id, references(:custom_exercises, on_delete: :nilify_all)
      add :repRange, :string
      timestamps(type: :utc_datetime)
    end
  end
end
