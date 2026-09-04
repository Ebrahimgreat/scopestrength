# ScopeStrength - personal trainer management application
# Copyright (C) 2026  Ebrahim Shahid Arshad
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# SPDX-License-Identifier: AGPL-3.0-or-later

defmodule Scopestrength.Clients.Client do
 use Ecto.Schema
  import Ecto.Changeset

  schema "clients" do
    field :age, :integer
    field :height, :decimal
    field :notes, :string
    field :sex, :string
    field :active, :boolean
    field :profile_picture_url, :string
    belongs_to :user, Scopestrength.Account.User
    belongs_to :trainer, Scopestrength.Trainers.Trainer

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
    |> cast(attrs, [:age, :user_id, :height, :notes, :sex, :trainer_id, :active, :profile_picture_url])
    |> validate_number(:age, greater_than_or_equal_to: 0)
    |> validate_number(:height, greater_than: 0)
    |> validate_inclusion(:sex, ["male", "female", "other"])
    |> validate_required([])
  end
end
