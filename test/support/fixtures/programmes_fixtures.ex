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

defmodule Scopestrength.ProgrammesFixtures do
  @moduledoc """
  Test helpers for programmes, templates and template exercises.

  `full_programme_fixture/1` builds a programme with one template holding
  one exercise with a rep range, which is what seeding progression needs.
  """

  import Scopestrength.AccountFixtures
  import Scopestrength.ExercisesFixtures

  alias Scopestrength.Programmes

  def programme_fixture(attrs \\ %{}) do
    attrs = Map.new(attrs)
    user_id = attrs[:user_id] || trainer_user_fixture().id

    {:ok, programme} =
      attrs
      |> Enum.into(%{
        name: "Programme #{System.unique_integer([:positive])}",
        description: "A programme",
        progression_method: "dynamic_double_progression",
        user_id: user_id
      })
      |> Programmes.create_programme()

    programme
  end

  def programme_template_fixture(attrs \\ %{}) do
    attrs = Map.new(attrs)
    programme_id = attrs[:programme_id] || programme_fixture().id

    {:ok, template} =
      attrs
      |> Enum.into(%{name: "Day #{System.unique_integer([:positive])}", programme_id: programme_id})
      |> Programmes.create_programme_template()

    template
  end

  def programme_details_fixture(attrs \\ %{}) do
    attrs = Map.new(attrs)
    template_id = attrs[:programme_template_id] || programme_template_fixture().id
    exercise_id = attrs[:exercise_id] || exercise_fixture().id

    {:ok, details} =
      attrs
      |> Enum.into(%{
        programme_template_id: template_id,
        exercise_id: exercise_id,
        set: "3",
        reps: "10",
        min_reps: 8,
        max_reps: 12
      })
      |> Programmes.create_programme_details()

    details
  end

  def full_programme_fixture(attrs \\ %{}) do
    attrs = Map.new(attrs)
    {exercise, attrs} = Map.pop(attrs, :exercise)
    exercise = exercise || exercise_fixture()

    programme = programme_fixture(attrs)
    template = programme_template_fixture(%{programme_id: programme.id})

    details =
      programme_details_fixture(%{
        programme_template_id: template.id,
        exercise_id: exercise.id,
        set: "2"
      })

    %{programme: programme, template: template, details: details, exercise: exercise}
  end
end
