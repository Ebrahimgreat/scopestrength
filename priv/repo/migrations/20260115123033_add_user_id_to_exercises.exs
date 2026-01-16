defmodule Crohnjobs.Repo.Migrations.AddUserIdToExercises do
  use Ecto.Migration

  def change do
    alter table(:exercises) do
      add :user_id, references(:users, on_delete: :delete_all)
    end
  end
end
