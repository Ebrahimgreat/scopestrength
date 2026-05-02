defmodule Scopestrength.Repo.Migrations.CreateProgressPhotos do
  use Ecto.Migration

  def change do
    create table(:progress_photos) do
      add :photo_url, :string
      add :date, :utc_datetime
      add :notes, :string
      add :client_id, references(:clients, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:progress_photos, [:client_id])
  end
end
