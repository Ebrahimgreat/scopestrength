defmodule Crohnjobs.Programmes.ProgrammeDetails do
  use Ecto.Schema
  import Ecto.Changeset

  schema "programme_details" do
    field :set, :string
    field :reps, :string
    field :rir, :integer
    belongs_to :exercise, Crohnjobs.Exercises.Exercise
    belongs_to :programme_template, Crohnjobs.Programmes.ProgrammeTemplate




    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(programme_details, attrs) do
    programme_details
    |> cast(attrs, [:set, :reps, :exercise_id, :rir, :programme_template_id])
    |> foreign_key_constraint(:exercise_id)
   |> foreign_key_constraint(:programme_template_id)

    |> validate_required([])
  end
end
