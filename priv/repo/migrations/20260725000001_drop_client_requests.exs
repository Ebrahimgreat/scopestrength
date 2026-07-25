defmodule Scopestrength.Repo.Migrations.DropClientRequests do
  use Ecto.Migration

  def up do
    drop table(:client_requests)
  end

  def down do
    create table(:client_requests) do
      add :client_id, references(:clients, on_delete: :delete_all)
      add :trainer_id, references(:trainers, on_delete: :delete_all)
      add :status, :string, default: "pending", null: false
      add :message, :text
      timestamps(type: :utc_datetime)
    end
  end
end
