defmodule Crohnjobs.Repo.Migrations.AlterClientsTable do
  use Ecto.Migration

  def change do
    alter table(:clients) do


    add :active, :boolean
    end

  end
end
