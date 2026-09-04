defmodule Scopestrength.Repo.Migrations.AddRepRangeToProgrammeDetails do
  use Ecto.Migration

  def change do
    alter table(:programme_details) do
      add :min_reps, :integer
      add :max_reps, :integer
    end
  end
end
