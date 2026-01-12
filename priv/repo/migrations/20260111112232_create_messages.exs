defmodule Crohnjobs.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :messages, :string
      add :room_id, :string
      add :text, :text, null: false

      timestamps(type: :utc_datetime)
    end
  end
end
