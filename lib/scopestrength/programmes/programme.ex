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

defmodule Scopestrength.Programmes.Programme do
  use Ecto.Schema
  import Ecto.Changeset

  schema "programme" do
 field :name, :string
 field :description, :string
 field :progression_method, :string
 belongs_to :user, Scopestrength.Account.User
 has_many :programmeTemplates, Scopestrength.Programmes.ProgrammeTemplate

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(programme, attrs) do
    programme
    |> cast(attrs, [:name, :description, :user_id, :progression_method])
    |> validate_required([])
  end
end
