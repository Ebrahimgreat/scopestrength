defmodule Crohnjobs.Repo.Migrations.AddUserIdToClients do
  use Ecto.Migration

  def change do
   alter table(:clients) do
     add :user_id, references(:users, on_delete: :delete_all), null: false
   end

  end
end
