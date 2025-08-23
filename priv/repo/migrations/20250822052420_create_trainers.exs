defmodule Crohnjobs.Repo.Migrations.CreateTrainers do
  use Ecto.Migration

  def change do
    create table(:trainers) do
      add :bio, :string
      add :specialization, :string
      add :user_id, references(:users, on_delete: :delete_all), null: false
      timestamps(type: :utc_datetime)
    end
  end
end
