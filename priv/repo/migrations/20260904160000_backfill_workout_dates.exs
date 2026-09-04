defmodule Scopestrength.Repo.Migrations.BackfillWorkoutDates do
  use Ecto.Migration

  def up do
    execute("UPDATE workouts SET date = inserted_at WHERE date IS NULL")
    alter table(:workouts) do
      modify :date, :utc_datetime, null: false
    end
  end

  def down do
    alter table(:workouts) do
      modify :date, :utc_datetime, null: true
    end
  end
end
