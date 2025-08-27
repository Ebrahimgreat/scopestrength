defmodule Crohnjobs.Repo.Migrations.UpdateClientsTable do
  use Ecto.Migration

  def change do
    alter table(:clients) do
      remove :user_id
      add :name, :string
    end

  end
end
