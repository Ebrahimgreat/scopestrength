defmodule Scopestrength.Trainers.Trainer do
  use Ecto.Schema
  import Ecto.Changeset

  schema "trainers" do
    field :bio, :string
    field :specialization, :string
    field :years_experience, :integer
    field :location, :string
    field :is_demo, :boolean
    field :style, :string
    field :format, :string
    field :price_per_month, :decimal
    field :instagram_url, :string
    field :availability, :boolean, default: true
    field :is_public, :boolean, default: false
    field :price_per_session, :decimal
    field :profile_picture_url, :string
    belongs_to :user, Scopestrength.Account.User
    has_many :clients, Scopestrength.Clients.Client
    has_many :certifications, Scopestrength.Trainers.Certification

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(trainer, attrs) do
    trainer
    |> cast(attrs, [
      :bio, :specialization, :years_experience, :location,
      :style, :format, :price_per_month, :instagram_url,
      :availability, :is_public, :user_id, :is_demo,
      :price_per_session, :profile_picture_url
    ])
    |> validate_required([])
    |> validate_number(:years_experience, greater_than_or_equal_to: 0)
    |> validate_number(:price_per_month, greater_than_or_equal_to: 0)
  end
end
