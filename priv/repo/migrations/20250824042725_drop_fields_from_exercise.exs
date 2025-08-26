defmodule Crohnjobs.Repo.Migrations.DropFieldsFromExercise do
  use Ecto.Migration

  def change do
    alter table(:exercises) do
      remove :is_custom
      remove :trainer_id

    end

  end
end
