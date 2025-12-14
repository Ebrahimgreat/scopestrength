defmodule Crohnjobs.Repo.Migrations.AddWeightToStrengthProgress do
  use Ecto.Migration

  def change do
    alter table(:strength_progress) do
      add :weight, :float
    end

  end
end
