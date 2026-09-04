defmodule Scopestrength.Repo.Migrations.MakeClientProgressionsPerSet do
  use Ecto.Migration

  def up do
    alter table(:client_progressions) do
      add :set_number, :integer
      add :progression_method, :string
      modify :min_reps, :integer, from: :float
      modify :max_reps, :integer, from: :float
    end

    execute "UPDATE client_progressions SET set_number = 1 WHERE set_number IS NULL"

    drop unique_index(:client_progressions, [:client_id, :exercise_id])
    create unique_index(:client_progressions, [:client_id, :exercise_id, :set_number])
  end

  def down do
    drop unique_index(:client_progressions, [:client_id, :exercise_id, :set_number])
    create unique_index(:client_progressions, [:client_id, :exercise_id])

    alter table(:client_progressions) do
      remove :set_number
      remove :progression_method
      modify :min_reps, :float, from: :integer
      modify :max_reps, :float, from: :integer
    end
  end
end
