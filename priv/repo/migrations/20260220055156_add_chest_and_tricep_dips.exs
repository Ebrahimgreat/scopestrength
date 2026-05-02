defmodule Scopestrength.Repo.Migrations.AddChestAndTricepDips do
  use Ecto.Migration

  def up do
    # Chest Dips (forward lean = chest dominant)
    execute """
    INSERT INTO exercises (name, muscle_id, equipment_id, is_unilateral, is_custom, inserted_at, updated_at)
    SELECT 'Chest Dips', mu.id, eq.id, false, false, NOW(), NOW()
    FROM muscles mu, equipment eq
    WHERE mu.name = 'Chest' AND eq.name = 'Bodyweight'
    AND NOT EXISTS (SELECT 1 FROM exercises WHERE name = 'Chest Dips');
    """

    # Tricep Dips (upright torso = tricep dominant)
    execute """
    INSERT INTO exercises (name, muscle_id, equipment_id, is_unilateral, is_custom, inserted_at, updated_at)
    SELECT 'Tricep Dips', mu.id, eq.id, false, false, NOW(), NOW()
    FROM muscles mu, equipment eq
    WHERE mu.name = 'Triceps' AND eq.name = 'Bodyweight'
    AND NOT EXISTS (SELECT 1 FROM exercises WHERE name = 'Tricep Dips');
    """

    # Chest Dips contributions
    execute """
    INSERT INTO exercise_muscle_contribution (exercise_id, muscle_id, role, multiplier, trainer_id, inserted_at, updated_at)
    SELECT e.id, m.id, 'primary', 1.0, NULL, NOW(), NOW()
    FROM exercises e, muscles m
    WHERE e.name = 'Chest Dips' AND m.name = 'Chest'
    AND NOT EXISTS (
      SELECT 1 FROM exercise_muscle_contribution emc
      WHERE emc.exercise_id = e.id AND emc.muscle_id = m.id
    );
    """

    execute """
    INSERT INTO exercise_muscle_contribution (exercise_id, muscle_id, role, multiplier, trainer_id, inserted_at, updated_at)
    SELECT e.id, m.id, 'secondary', 0.5, NULL, NOW(), NOW()
    FROM exercises e, muscles m
    WHERE e.name = 'Chest Dips' AND m.name = 'Triceps'
    AND NOT EXISTS (
      SELECT 1 FROM exercise_muscle_contribution emc
      WHERE emc.exercise_id = e.id AND emc.muscle_id = m.id
    );
    """

    execute """
    INSERT INTO exercise_muscle_contribution (exercise_id, muscle_id, role, multiplier, trainer_id, inserted_at, updated_at)
    SELECT e.id, m.id, 'secondary', 0.5, NULL, NOW(), NOW()
    FROM exercises e, muscles m
    WHERE e.name = 'Chest Dips' AND m.name = 'Front Delts'
    AND NOT EXISTS (
      SELECT 1 FROM exercise_muscle_contribution emc
      WHERE emc.exercise_id = e.id AND emc.muscle_id = m.id
    );
    """

    # Tricep Dips contributions
    execute """
    INSERT INTO exercise_muscle_contribution (exercise_id, muscle_id, role, multiplier, trainer_id, inserted_at, updated_at)
    SELECT e.id, m.id, 'primary', 1.0, NULL, NOW(), NOW()
    FROM exercises e, muscles m
    WHERE e.name = 'Tricep Dips' AND m.name = 'Triceps'
    AND NOT EXISTS (
      SELECT 1 FROM exercise_muscle_contribution emc
      WHERE emc.exercise_id = e.id AND emc.muscle_id = m.id
    );
    """

    execute """
    INSERT INTO exercise_muscle_contribution (exercise_id, muscle_id, role, multiplier, trainer_id, inserted_at, updated_at)
    SELECT e.id, m.id, 'secondary', 0.3, NULL, NOW(), NOW()
    FROM exercises e, muscles m
    WHERE e.name = 'Tricep Dips' AND m.name = 'Chest'
    AND NOT EXISTS (
      SELECT 1 FROM exercise_muscle_contribution emc
      WHERE emc.exercise_id = e.id AND emc.muscle_id = m.id
    );
    """

    execute """
    INSERT INTO exercise_muscle_contribution (exercise_id, muscle_id, role, multiplier, trainer_id, inserted_at, updated_at)
    SELECT e.id, m.id, 'secondary', 0.5, NULL, NOW(), NOW()
    FROM exercises e, muscles m
    WHERE e.name = 'Tricep Dips' AND m.name = 'Front Delts'
    AND NOT EXISTS (
      SELECT 1 FROM exercise_muscle_contribution emc
      WHERE emc.exercise_id = e.id AND emc.muscle_id = m.id
    );
    """
  end

  def down do
    execute """
    DELETE FROM exercise_muscle_contribution
    WHERE exercise_id IN (SELECT id FROM exercises WHERE name IN ('Chest Dips', 'Tricep Dips'));
    """

    execute """
    DELETE FROM exercises WHERE name IN ('Chest Dips', 'Tricep Dips');
    """
  end
end
