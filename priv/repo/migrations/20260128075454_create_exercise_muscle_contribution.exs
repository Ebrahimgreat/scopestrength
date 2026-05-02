defmodule Scopestrength.Repo.Migrations.CreateExerciseMuscleContribution do
  use Ecto.Migration

  def change do
    create table(:exercise_muscle_contribution) do
      add :exercise_id, references(:exercises, on_delete: :delete_all), null: false
      add :muscle_id, references(:muscles, on_delete: :delete_all), null: false
      add :trainer_id, references(:users, on_delete: :nilify_all)
      add :role, :string, null: false
      add :multiplier, :float, null: false

      timestamps(type: :utc_datetime)
    end
  end
end
