defmodule Scopestrength.Repo.Migrations.AddProgressionStatusToWorkoutDetails do
  use Ecto.Migration

  def change do
    alter table(:workout_details) do
      add :progression_status, :string, default: "hold"    end

  end
end
