defmodule Scopestrength.Repo.Migrations.DropMarketplaceFieldsFromTrainers do
  use Ecto.Migration

  def up do
    drop table(:trainer_certifications)

    alter table(:trainers) do
      remove :years_experience
      remove :location
      remove :style
      remove :format
      remove :price_per_month
      remove :price_per_session
      remove :instagram_url
      remove :availability
      remove :is_public
    end
  end

  def down do
    alter table(:trainers) do
      add :years_experience, :integer
      add :location, :string
      add :style, :string
      add :format, :string
      add :price_per_month, :decimal, precision: 10, scale: 2
      add :price_per_session, :decimal, precision: 10, scale: 2
      add :instagram_url, :string
      add :availability, :boolean, default: true, null: false
      add :is_public, :boolean, default: false, null: false
    end

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
