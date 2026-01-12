defmodule Crohnjobs.Repo.Migrations.AddInviteCodeToTrainerTable do
  use Ecto.Migration

  def change do
    alter table(:trainers) do
      add :invite_code, :string
    end

  end
end
