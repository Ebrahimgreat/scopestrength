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

defmodule Scopestrength.TrainingFixtures do
  @moduledoc """
  Test helpers for workouts and logged sets.
  """

  import Scopestrength.ExercisesFixtures
  import Scopestrength.PeopleFixtures

  alias Scopestrength.Training

  def workout_fixture(attrs \\ %{}) do
    attrs = Map.new(attrs)
    client_id = attrs[:client_id] || client_fixture().id

    {:ok, workout} =
      attrs
      |> Enum.into(%{
        name: "Workout #{System.unique_integer([:positive])}",
        client_id: client_id,
        date: DateTime.utc_now() |> DateTime.truncate(:second)
      })
      |> Training.create_workout()

    workout
  end

  def workout_details_fixture(attrs \\ %{}) do
    attrs = Map.new(attrs)
    workout_id = attrs[:workout_id] || workout_fixture().id
    exercise_id = attrs[:exercise_id] || exercise_fixture().id

    {:ok, details} =
      attrs
      |> Enum.into(%{
        workout_id: workout_id,
        exercise_id: exercise_id,
        set: 1,
        reps: 10.0,
        weight: 50.0,
        side: "both"
      })
      |> Training.create_workout_details()

    details
  end
end
