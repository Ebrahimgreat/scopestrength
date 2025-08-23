defmodule Crohnjobs.Repo.Migrations.CreateClients do
  use Ecto.Migration

  def change do
    create table(:clients) do
      add :height, :decimal
      add :sex, :string
      add :age, :integer
      add :notes, :string
      add :trainer_id, references(:trainers, on_delete: :delete_all)


      timestamps(type: :utc_datetime)
    end
  end
end
