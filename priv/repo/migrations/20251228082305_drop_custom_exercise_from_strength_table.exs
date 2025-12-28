defmodule Crohnjobs.Repo.Migrations.DropCustomExerciseFromStrengthTable do
  use Ecto.Migration

  def change do
    alter table(:strength_progress) do
      remove :custom_exercise_id
    end

  end
end
