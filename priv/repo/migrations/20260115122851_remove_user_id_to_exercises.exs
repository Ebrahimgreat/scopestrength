defmodule Crohnjobs.Repo.Migrations.RemoveUserIdToExercises do
  use Ecto.Migration

  def change do
    alter table(:exercises) do
      remove :trainer_id
    end
  end
end
