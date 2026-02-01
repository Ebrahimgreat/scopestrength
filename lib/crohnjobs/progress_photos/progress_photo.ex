defmodule Crohnjobs.ProgressPhotos.ProgressPhoto do
  use Ecto.Schema
  import Ecto.Changeset

  schema "progress_photos" do
    field :date, :utc_datetime
    field :photo_url, :string
    field :notes, :string
    belongs_to :client, Crohnjobs.Clients.Client

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(progress_photo, attrs) do
    progress_photo
    |> cast(attrs, [:photo_url, :date, :notes, :client_id])
    |> validate_required([:photo_url, :date, :client_id])
  end
end
