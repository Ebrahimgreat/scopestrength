defmodule Scopestrength.Repo.Migrations.AddObanJobsTable do
  use Ecto.Migration

  def change do
    Oban.Migration.up(version: 12)

  end
  def down do
    Oban.Migration.down(version: 1)
  end
end
