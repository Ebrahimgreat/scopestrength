defmodule Crohnjobs.Repo.Migrations.CreateSubscriptions do
  use Ecto.Migration

  def change do
    create table(:subscriptions) do
      add :name, :string
      add :plan, :string
      add :trial_start, :utc_datetime
      add :trial_end, :utc_datetime
      add :paid_until, :utc_datetime
      add :user_id, references(:users, on_delete: :delete_all), null: false





      timestamps(type: :utc_datetime)
    end
  end
end
