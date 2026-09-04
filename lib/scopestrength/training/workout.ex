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

defmodule Scopestrength.Training.Workout do
  use Ecto.Schema
  import Ecto.Changeset

  schema "workouts" do
    field :name, :string
    field :date, :utc_datetime
    field :notes, :string
    belongs_to :client, Scopestrength.Clients.Client
    has_many :workoutDetails,Scopestrength.Training.WorkoutDetails

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(workout, attrs) do
    workout
    |> cast(attrs, [:name, :date, :client_id, :notes])
    |> validate_required([:client_id])
    |> put_default_date()
  end

  defp put_default_date(changeset) do
    case get_field(changeset, :date) do
      nil -> put_change(changeset, :date, DateTime.utc_now() |> DateTime.truncate(:second))
      _date -> changeset
    end
  end
end
