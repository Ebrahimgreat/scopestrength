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

defmodule ScopestrengthWeb.Api.ClientJSON do
  @moduledoc """
  Renders the read-only client API. Shapes here are consumed by an LLM agent, so
  they favour named fields and plain numbers over ids and nesting.
  """

  def summary(%{summary: summary}) do
    %{
      total_workouts: summary.total_workouts,
      total_sets: summary.total_sets,
      last_workout_at: summary.last_workout_at,
      personal_record: personal_record(summary.pr)
    }
  end

  def workouts(%{workouts: workouts}) do
    %{workouts: Enum.map(workouts, &workout/1)}
  end

  def created_workout(%{workout: workout}) do
    %{workout: workout(workout)}
  end

  def exercises(%{exercises: exercises}) do
    %{exercises: Enum.map(exercises, &exercise/1)}
  end

  def progressions(%{progressions: progressions}) do
    %{progressions: Enum.map(progressions, &progression/1)}
  end

  def error(%{detail: detail}) do
    %{errors: %{detail: detail}}
  end

  defp personal_record(nil), do: nil

  defp personal_record(pr) do
    %{
      exercise: pr.exercise_name,
      weight: pr.weight,
      reps: pr.reps,
      date: pr.date
    }
  end

  defp workout(workout) do
    %{
      id: workout.id,
      name: workout.name,
      date: workout.date || workout.inserted_at,
      notes: workout.notes,
      sets: Enum.map(workout.workoutDetails, &set/1)
    }
  end

  defp set(detail) do
    %{
      exercise: detail.exercise && detail.exercise.name,
      exercise_id: detail.exercise_id,
      set: detail.set,
      reps: detail.reps,
      weight: detail.weight,
      rir: detail.rir,
      rpe: detail.rpe,
      side: detail.side
    }
  end

  defp exercise(exercise) do
    %{
      id: exercise.id,
      name: exercise.name,
      is_custom: exercise.is_custom,
      is_unilateral: exercise.is_unilateral
    }
  end

  defp progression(row) do
    %{
      exercise: row.exercise && row.exercise.name,
      exercise_id: row.exercise_id,
      set_number: row.set_number,
      side: row.side,
      progression_method: row.progression_method,
      min_reps: row.min_reps,
      max_reps: row.max_reps,
      target_weight: row.target_weight,
      status: row.status
    }
  end
end
