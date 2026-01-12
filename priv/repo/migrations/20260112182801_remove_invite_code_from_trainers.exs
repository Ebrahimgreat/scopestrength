defmodule Crohnjobs.Repo.Migrations.RemoveInviteCodeFromTrainers do
  use Ecto.Migration

  def change do
    alter table(:trainers) do
      remove :invite_code, :string
    end
  end
end
