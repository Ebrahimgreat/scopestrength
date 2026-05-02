defmodule Scopestrength.Notifications.Notification do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notifications" do
    field :actor_id, :integer
    field :actor_type, :string
    field :recipient_id, :integer
    field :recipient_type, :string
    field :type, :string
    field :data, :map
    field :read_at, :utc_datetime



    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:actor_id, :actor_type, :recipient_id, :recipient_type, :type, :data, :read_at])
    |> validate_required([])
  end
end
