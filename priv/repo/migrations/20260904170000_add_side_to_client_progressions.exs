defmodule Scopestrength.Repo.Migrations.AddSideToClientProgressions do
  use Ecto.Migration

  def up do
    alter table(:client_progressions) do
      add :side, :string, null: false, default: "both"
    end

    drop unique_index(:client_progressions, [:client_id, :exercise_id, :set_number])
    create unique_index(:client_progressions, [:client_id, :exercise_id, :set_number, :side])

    execute """
    UPDATE client_progressions cp
    SET side = 'left'
    FROM exercises e
    WHERE e.id = cp.exercise_id AND e.is_unilateral
    """

    execute """
    INSERT INTO client_progressions
      (client_id, exercise_id, set_number, side, progression_method, min_reps, max_reps, target_weight, status, inserted_at, updated_at)
    SELECT client_id, exercise_id, set_number, 'right', progression_method, min_reps, max_reps, target_weight, status, inserted_at, updated_at
    FROM client_progressions
    WHERE side = 'left'
    """
  end

  def down do
    execute "DELETE FROM client_progressions WHERE side = 'right'"
    drop unique_index(:client_progressions, [:client_id, :exercise_id, :set_number, :side])
    create unique_index(:client_progressions, [:client_id, :exercise_id, :set_number])

    alter table(:client_progressions) do
      remove :side
    end
  end
end
