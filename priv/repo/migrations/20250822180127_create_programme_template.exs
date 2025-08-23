defmodule Crohnjobs.Repo.Migrations.CreateProgrammeTemplate do
  use Ecto.Migration

  def change do
    create table(:programme_template) do
      add :name, :string
      add :programme_id, references(:programme, on_delete: :delete_all)


      timestamps(type: :utc_datetime)
    end
  end
end
