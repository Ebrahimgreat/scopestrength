defmodule Crohnjobs.Subscriptions.Subscription do
  use Ecto.Schema
  import Ecto.Changeset

  schema "subscriptions" do
    field :name, :string
    field :plan, :string
    field :trial_start, :utc_datetime
    field :trial_end, :utc_datetime
    field :paid_until , :utc_datetime
    belongs_to :user, Crohnjobs.Account.User




    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(subscription, attrs) do
    subscription
    |> cast(attrs, [:name, :plan, :trial_start, :trial_end, :paid_until, :user_id])
    |> validate_required([:plan, :user_id])
  end
end
