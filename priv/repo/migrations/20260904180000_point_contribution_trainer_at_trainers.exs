defmodule Scopestrength.Repo.Migrations.PointContributionTrainerAtTrainers do
  use Ecto.Migration

  def up do
    drop constraint(:exercise_muscle_contribution, "exercise_muscle_contribution_trainer_id_fkey")

    execute """
    UPDATE exercise_muscle_contribution
    SET trainer_id = NULL
    WHERE trainer_id IS NOT NULL AND trainer_id NOT IN (SELECT id FROM trainers)
    """

    alter table(:exercise_muscle_contribution) do
      modify :trainer_id, references(:trainers, on_delete: :nilify_all)
    end
  end

  def down do
    drop constraint(:exercise_muscle_contribution, "exercise_muscle_contribution_trainer_id_fkey")

    execute """
    UPDATE exercise_muscle_contribution
    SET trainer_id = NULL
    WHERE trainer_id IS NOT NULL AND trainer_id NOT IN (SELECT id FROM users)
    """

    alter table(:exercise_muscle_contribution) do
      modify :trainer_id, references(:users, on_delete: :nilify_all)
    end
  end
end
