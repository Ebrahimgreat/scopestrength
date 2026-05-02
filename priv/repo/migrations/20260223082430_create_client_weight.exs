defmodule Scopestrength.Repo.Migrations.CreateClientWeight do
  use Ecto.Migration

  def change do
    create table(:client_weight) do
      add :date, :date
      add :weight, :decimal
      add :client_id, references(:clients, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end
  end
end
