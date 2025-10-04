defmodule Crohnjobs.Repo.Migrations.AddRirToProgrammeDetails do
  use Ecto.Migration

  def change do
    alter  table(:programme_details)do
    add :rir, :integer
    end

  end
end
