defmodule Scopestrength.Repo.Migrations.CreateLeads do
  use Ecto.Migration

  def change do
    create table(:leads) do
      add :email, :string, null: false
      add :demo_user_id, references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:leads, [:email])
    create index(:leads, [:demo_user_id])
  end
end
