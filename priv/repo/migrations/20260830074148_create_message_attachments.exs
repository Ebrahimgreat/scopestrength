defmodule Scopestrength.Repo.Migrations.CreateMessageAttachments do
  use Ecto.Migration

  def change do
    create table(:message_attachments) do
      add :file_url, :string, null: false
      add :file_name, :string
      add :content_type, :string
      add :file_size, :integer
      add :message_id, references(:messages, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:message_attachments, [:message_id])
  end
end
