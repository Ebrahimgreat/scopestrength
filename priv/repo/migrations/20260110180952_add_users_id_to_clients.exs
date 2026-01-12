defmodule Crohnjobs.Repo.Migrations.AddUsersIdToClients do
  use Ecto.Migration

  def change do
    alter table(:clients) do
    add :user_id, references(:users, on_delete: :delete_all)
    end
  end
end
