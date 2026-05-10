defmodule Scopestrength.Repo.Migrations.DropInvitesTable do
  use Ecto.Migration

  def up do
    drop_if_exists index(:invites, [:email])
    drop_if_exists index(:invites, [:trainer_id])
    drop_if_exists unique_index(:invites, [:code])
    drop_if_exists table(:invites)
  end

  def down do
    create table(:invites) do
      add :code, :string, null: false
      add :email, :string, null: false
      add :used, :boolean, default: false, null: false
      add :trainer_id, references(:trainers, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:invites, [:code])
    create index(:invites, [:trainer_id])
    create index(:invites, [:email])
  end
end
