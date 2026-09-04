defmodule Scopestrength.Repo.Migrations.CreateClientProgression do
  use Ecto.Migration

  def change do
    create table(:client_progressions) do
      add :exercise_id, references(:exercises, on_delete: :delete_all)
      add :client_id, references(:clients, on_delete: :delete_all)
      add :min_reps, :float
      add :max_reps, :float
      add :target_weight, :float

      timestamps(type: :utc_datetime)
    end

    create unique_index(:client_progressions, [:client_id, :exercise_id])
  end
end
