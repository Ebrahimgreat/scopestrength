defmodule Crohnjobs.Repo.Migrations.RemoveNameFromClients do
  use Ecto.Migration

  def change do
    alter table(:clients) do
      remove :name, :string
    end
  end
end
