defmodule Crohnjobs.Repo.Migrations.AddSideToWorkoutDetails do
  use Ecto.Migration

  def change do
    alter table(:workout_details) do
      add :side, :string, default: "both", null: false
    end
  end
end
