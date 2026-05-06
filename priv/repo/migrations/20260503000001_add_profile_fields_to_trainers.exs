defmodule Scopestrength.Repo.Migrations.AddProfileFieldsToTrainers do
  use Ecto.Migration

  def change do
    alter table(:trainers) do
      add :years_experience, :integer
      add :location, :string
      add :style, :string
      add :format, :string
      add :price_per_month, :decimal, precision: 10, scale: 2
      add :instagram_url, :string
      add :availability, :boolean, default: true, null: false
      add :is_public, :boolean, default: false, null: false
    end
  end
end
