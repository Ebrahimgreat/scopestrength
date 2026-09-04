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

defmodule Scopestrength.ExercisesFixtures do
  @moduledoc """
  Test helpers for muscles, equipment and exercises.
  """

  alias Scopestrength.{Exercise, Exercises, Repo}

  def muscles_fixture(attrs \\ %{}) do
    {:ok, muscles} =
      attrs
      |> Enum.into(%{name: "Muscle #{System.unique_integer([:positive])}"})
      |> Exercises.create_muscles()

    muscles
  end

  def equipment_fixture(attrs \\ %{}) do
    {:ok, equipment} =
      attrs
      |> Enum.into(%{name: "Equipment #{System.unique_integer([:positive])}"})
      |> Exercises.create_equipment()

    equipment
  end

  def exercise_fixture(attrs \\ %{}) do
    attrs = Map.new(attrs)
    muscle_id = attrs[:muscle_id] || muscles_fixture().id
    equipment_id = attrs[:equipment_id] || equipment_fixture().id

    {:ok, exercise} =
      attrs
      |> Enum.into(%{
        name: "Exercise #{System.unique_integer([:positive])}",
        muscle_id: muscle_id,
        equipment_id: equipment_id,
        is_custom: false,
        is_unilateral: false
      })
      |> Exercise.create_exercise()

    Repo.preload(exercise, [:muscle, :equipment])
  end

  def unilateral_exercise_fixture(attrs \\ %{}) do
    exercise_fixture(Enum.into(attrs, %{is_unilateral: true}))
  end

  def exercise_muscle_contribution_fixture(attrs \\ %{}) do
    attrs = Map.new(attrs)
    exercise = attrs[:exercise] || exercise_fixture()

    {:ok, contribution} =
      attrs
      |> Map.delete(:exercise)
      |> Enum.into(%{
        exercise_id: exercise.id,
        muscle_id: exercise.muscle_id,
        role: "primary",
        multiplier: 1.0
      })
      |> Exercises.create_exercise_muscle_contribution()

    contribution
  end
end
