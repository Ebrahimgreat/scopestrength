defmodule Scopestrength.Trainers.Certification do
  use Ecto.Schema
  import Ecto.Changeset

  schema "trainer_certifications" do
    field :name, :string
    field :issuing_body, :string
    field :issued_at, :date
    field :expires_at, :date

    belongs_to :trainer, Scopestrength.Trainers.Trainer

    timestamps(type: :utc_datetime)
  end

  def changeset(certification, attrs) do
    certification
    |> cast(attrs, [:name, :issuing_body, :issued_at, :expires_at, :trainer_id])
    |> validate_required([:name, :trainer_id])
  end
end
