defmodule Scopestrength.Repo.Migrations.AddIsDemoToTrainers do
  use Ecto.Migration

  def change do
    alter table(:trainers) do
      add :is_demo, :boolean, default: false
    end

  end
end
