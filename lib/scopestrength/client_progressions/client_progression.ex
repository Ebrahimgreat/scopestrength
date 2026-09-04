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

defmodule Scopestrength.ClientProgressions.ClientProgression do
  use Ecto.Schema
  import Ecto.Changeset

  alias Scopestrength.Training.WorkoutDetails

  @sides ["both", "left", "right"]

  schema "client_progressions" do
    field :set_number, :integer
    field :side, :string, default: "both"
    field :progression_method, :string
    field :min_reps, :integer
    field :max_reps, :integer
    field :target_weight, :float
    field :status, :string, default: "hold"
    belongs_to :exercise, Scopestrength.Exercises.Exercise
    belongs_to :client, Scopestrength.Clients.Client

    timestamps(type: :utc_datetime)
  end

  def sides, do: @sides

  @doc false
  def changeset(client_progression, attrs) do
    client_progression
    |> cast(attrs, [
      :set_number,
      :side,
      :progression_method,
      :min_reps,
      :max_reps,
      :target_weight,
      :status,
      :exercise_id,
      :client_id
    ])
    |> validate_required([:client_id, :exercise_id, :set_number, :side])
    |> validate_inclusion(:side, @sides)
    |> validate_inclusion(:status, WorkoutDetails.progression_statuses())
    |> validate_number(:set_number, greater_than: 0)
    |> validate_number(:min_reps, greater_than: 0)
    |> validate_number(:max_reps, greater_than: 0)
    |> validate_max_reps_not_below_min()
    |> foreign_key_constraint(:exercise_id)
    |> foreign_key_constraint(:client_id)
    |> unique_constraint([:client_id, :exercise_id, :set_number, :side])
  end

  defp validate_max_reps_not_below_min(changeset) do
    min = get_field(changeset, :min_reps)
    max = get_field(changeset, :max_reps)

    if is_number(min) and is_number(max) and max < min do
      add_error(changeset, :max_reps, "must be greater than or equal to min_reps")
    else
      changeset
    end
  end
end
