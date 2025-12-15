defmodule Crohnjobs.Repo.Migrations.CreateClientNotes do
  use Ecto.Migration

  def change do
    create table(:client_notes) do
      add :date, :date
      add :client_id, references(:clients, on_delete: :delete_all)
      add :notes, :string

      timestamps(type: :utc_datetime)
    end
  end
end
