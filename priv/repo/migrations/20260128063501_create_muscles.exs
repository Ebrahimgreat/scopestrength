defmodule Scopestrength.Repo.Migrations.CreateMuscles do
  use Ecto.Migration

  def change do
    create table(:muscles) do
      add :name, :string

      timestamps(type: :utc_datetime)
    end
  end
end
