defmodule Crohnjobs.Repo.Migrations.AddRirToWorkouts do
  use Ecto.Migration

  def change do
    alter table(:workout_details) do
      add :rir, :float
    end

  end
end
