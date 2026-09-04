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

defmodule Scopestrength.Training.WorkoutDetails do
  use Ecto.Schema
  import Ecto.Changeset

  @progression_statuses ["hold", "none", "progress", "reduce"]

  def progression_statuses, do: @progression_statuses

  schema "workout_details" do
    field :reps, :float
    field :weight, :float
    field :set, :integer
    field :rir, :float, default: 0.0
    field :rpe, :float
    field :side, :string, default: "both"
    field :progression_status, :string, default: "hold"
    belongs_to :exercise, Scopestrength.Exercises.Exercise
    belongs_to :workout, Scopestrength.Training.Workout
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(workout_details, attrs) do
    workout_details
    |> cast(attrs, [
      :reps,
      :weight,
      :set,
      :side,
      :workout_id,
      :rir,
      :rpe,
      :exercise_id,
      :progression_status
    ])
    |> validate_required([])
    |> validate_inclusion(:side, ["both", "left", "right"])
    |> validate_inclusion(:progression_status, @progression_statuses)
    |> validate_number(:rpe, greater_than_or_equal_to: 1, less_than_or_equal_to: 10)
  end
end
