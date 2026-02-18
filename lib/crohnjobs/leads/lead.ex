defmodule Crohnjobs.Leads.Lead do
  use Ecto.Schema
  import Ecto.Changeset

  schema "leads" do
    field :email, :string
    belongs_to :demo_user, Crohnjobs.Account.User

    timestamps(type: :utc_datetime)
  end

  def changeset(lead, attrs) do
    lead
    |> cast(attrs, [:email, :demo_user_id])
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email")
    |> update_change(:email, &String.downcase/1)
    |> unique_constraint(:email, message: "has already been used for a demo")
  end
end
