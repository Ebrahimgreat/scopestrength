defmodule Crohnjobs.Clients.Client do
 use Ecto.Schema
  import Ecto.Changeset

  schema "clients" do
    field :age, :integer
    field :height, :decimal
    field :notes, :string
    field :sex, :string
    field :active, :boolean
    belongs_to :user, Crohnjobs.Account.User
    belongs_to :trainer, Crohnjobs.Trainers.Trainer

    timestamps(type: :utc_datetime)
  end

  @spec changeset(
          {map(),
           %{
             optional(atom()) =>
               atom()
               | {:array | :assoc | :embed | :in | :map | :parameterized | :supertype | :try,
                  any()}
           }}
          | %{
              :__struct__ => atom() | %{:__changeset__ => any(), optional(any()) => any()},
              optional(atom()) => any()
            },
          :invalid | %{optional(:__struct__) => none(), optional(atom() | binary()) => any()}
        ) :: Ecto.Changeset.t()
  @doc false
  def changeset(client, attrs) do
    client
    |> cast(attrs, [:age, :user_id, :height, :notes, :sex, :trainer_id, :active])



    |> validate_required([])
  end
end
