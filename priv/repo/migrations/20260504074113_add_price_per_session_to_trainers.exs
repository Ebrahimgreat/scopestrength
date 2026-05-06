defmodule Scopestrength.Repo.Migrations.AddPricePerSessionToTrainers do
  use Ecto.Migration

  def change do
    alter table(:trainers) do
      add :price_per_session, :decimal, precision: 10, scale: 2
    end

  end
end
