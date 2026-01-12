defmodule Crohnjobs.Chat.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    field :text, :string
    field :room_id, :string
    belongs_to :user, Crohnjobs.Account.User


    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:text, :room_id, :user_id])
    |> validate_required([])
  end
end
