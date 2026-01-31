defmodule Crohnjobs.Repo.Migrations.AddNotesToWorkout do
  use Ecto.Migration

  def change do
    alter table(:workouts) do
      add :notes, :string
    end

  end
end
