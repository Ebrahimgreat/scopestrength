defmodule Crohnjobs.Repo.Migrations.AddProfilePictureToClients do
  use Ecto.Migration

  def change do
    alter table(:clients) do
      add :profile_picture_url, :string
    end
  end
end
