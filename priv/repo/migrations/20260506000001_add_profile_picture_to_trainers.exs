defmodule Scopestrength.Repo.Migrations.AddProfilePictureToTrainers do
  use Ecto.Migration

  def change do
    alter table(:trainers) do
      add :profile_picture_url, :string
    end
  end
end
