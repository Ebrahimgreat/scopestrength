defmodule Scopestrength.Repo.Migrations.CreateNotifications do
  use Ecto.Migration

  def change do
    create table(:notifications) do
      add :actor_id, :bigint, null: false
      add :actor_type, :string, null: false

      add :recipient_id, :bigint, null: false
      add :recipient_type, :string, null: false

      add :type, :string, null: false
      add :data, :map

      add :read_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end
  end
end
