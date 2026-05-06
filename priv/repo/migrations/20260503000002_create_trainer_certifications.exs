defmodule Scopestrength.Repo.Migrations.CreateTrainerCertifications do
  use Ecto.Migration

  def change do
    create table(:trainer_certifications) do
      add :name, :string, null: false
      add :issuing_body, :string
      add :issued_at, :date
      add :expires_at, :date
      add :trainer_id, references(:trainers, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:trainer_certifications, [:trainer_id])
  end
end
