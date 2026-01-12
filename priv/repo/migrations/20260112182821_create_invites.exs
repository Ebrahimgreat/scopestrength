defmodule Crohnjobs.Repo.Migrations.CreateInvites do
  use Ecto.Migration

  def change do
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
