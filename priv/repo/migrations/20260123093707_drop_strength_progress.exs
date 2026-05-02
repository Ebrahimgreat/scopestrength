defmodule Scopestrength.Repo.Migrations.DropStrengthProgress do
  use Ecto.Migration

  def change do
    drop table(:strength_progress)

  end
end
