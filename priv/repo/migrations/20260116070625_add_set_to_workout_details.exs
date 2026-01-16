defmodule Crohnjobs.Repo.Migrations.AddSetToWorkoutDetails do
  use Ecto.Migration

  def change do
    alter table(:workout_details) do
      add :set, :integer
    end
  end
end
