defmodule :"Elixir.Crohnjobs.Repo.Migrations.Remove-equipment-and-type" do
  use Ecto.Migration

  def change do
    alter table(:exercises) do
      remove :type, :string
      remove :equipment, :string
      add :muscle_id, references(:muscles, on_delete: :nothing)
      add :equipment_id, references(:equipment, on_delete: :nothing)
    end

    create index(:exercises, [:muscle_id])
    create index(:exercises, [:equipment_id])
  end
end
