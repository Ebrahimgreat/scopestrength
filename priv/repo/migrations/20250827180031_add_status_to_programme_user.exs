defmodule Crohnjobs.Repo.Migrations.AddStatusToProgrammeUser do
  use Ecto.Migration

  def change do
    alter table(:programmeuser) do
      add :is_active, :boolean, default: false
    end

  end
end
