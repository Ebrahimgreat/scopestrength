defmodule Crohnjobs.Repo.Migrations.CreateProgrammeuser do
  use Ecto.Migration

  def change do
    create table(:programmeuser) do
      add :programme_id, references(:programme, on_delete: :delete_all)
      add :client_id, references(:clients, on_delete: :delete_all)
      timestamps(type: :utc_datetime)
    end
  end
end
