defmodule Scopestrength.Repo.Migrations.AddMissingMuscleContributions do
  use Ecto.Migration

  def up do
    execute """
    INSERT INTO exercise_muscle_contribution (exercise_id, muscle_id, role, multiplier, trainer_id, inserted_at, updated_at)
    SELECT e.id, m.id, 'secondary', 0.5, NULL, NOW(), NOW()
    FROM exercises e, muscles m
    WHERE m.name = 'Front Delts'
    AND e.name IN (
      'Decline Barbell Press',
      'Decline Dumbbell Press',
      'Machine Chest Press',
      'Close Grip Bench Press',
      'Bodyweight Dips'
    )
    AND NOT EXISTS (
      SELECT 1 FROM exercise_muscle_contribution emc
      WHERE emc.exercise_id = e.id AND emc.muscle_id = m.id
    );
    """

    execute """
    INSERT INTO exercise_muscle_contribution (exercise_id, muscle_id, role, multiplier, trainer_id, inserted_at, updated_at)
    SELECT e.id, m.id, 'secondary', 0.5, NULL, NOW(), NOW()
    FROM exercises e, muscles m
    WHERE m.name = 'Rear Delts'
    AND e.name IN (
      'Barbell Bent Over Row',
      'Dumbbell Row (One Arm)',
      'Cable Row',
      'Seated Row',
      'Lat Pulldown',
      'Wide Lat Pulldown',
      'Pull Up',
      'Chin Up'
    )
    AND NOT EXISTS (
      SELECT 1 FROM exercise_muscle_contribution emc
      WHERE emc.exercise_id = e.id AND emc.muscle_id = m.id
    );
    """

    execute """
    INSERT INTO exercise_muscle_contribution (exercise_id, muscle_id, role, multiplier, trainer_id, inserted_at, updated_at)
    SELECT e.id, m.id, 'secondary', 0.5, NULL, NOW(), NOW()
    FROM exercises e, muscles m
    WHERE m.name = 'Biceps' AND e.name = 'Wide Grip Cable Row'
    AND NOT EXISTS (
      SELECT 1 FROM exercise_muscle_contribution emc
      WHERE emc.exercise_id = e.id AND emc.muscle_id = m.id
    );
    """
  end

  def down do
    execute """
    DELETE FROM exercise_muscle_contribution
    WHERE muscle_id = (SELECT id FROM muscles WHERE name = 'Front Delts')
    AND role = 'secondary'
    AND exercise_id IN (
      SELECT id FROM exercises WHERE name IN (
        'Decline Barbell Press', 'Decline Dumbbell Press',
        'Machine Chest Press', 'Close Grip Bench Press', 'Bodyweight Dips'
      )
    );
    """

    execute """
    DELETE FROM exercise_muscle_contribution
    WHERE muscle_id = (SELECT id FROM muscles WHERE name = 'Rear Delts')
    AND role = 'secondary'
    AND exercise_id IN (
      SELECT id FROM exercises WHERE name IN (
        'Barbell Bent Over Row', 'Dumbbell Row (One Arm)', 'Cable Row',
        'Seated Row', 'Lat Pulldown', 'Wide Lat Pulldown', 'Pull Up', 'Chin Up'
      )
    );
    """
  end
end
