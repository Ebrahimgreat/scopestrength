defmodule Scopestrength.Repo.Migrations.AddUserIdToProgramme do
  use Ecto.Migration

  def up do
    alter table(:programme) do
      add :user_id, references(:users, on_delete: :delete_all)
    end

    # Migrate existing data: copy trainer's user_id into programme.user_id
    execute """
    UPDATE programme
    SET user_id = t.user_id
    FROM trainers t
    WHERE programme.trainer_id = t.id
    """

    alter table(:programme) do
      remove :trainer_id
    end

    create index(:programme, [:user_id])
  end

  def down do
    alter table(:programme) do
      add :trainer_id, references(:trainers, on_delete: :nothing)
    end

    execute """
    UPDATE programme
    SET trainer_id = t.id
    FROM trainers t
    WHERE programme.user_id = t.user_id
    """

    alter table(:programme) do
      remove :user_id
    end
  end
end
