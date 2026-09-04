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

defmodule Scopestrength.ClientProgressions do
  @moduledoc """
  Handles client progression state and coordinates progression
  evaluation after completed workout sets.

  A progression row is identified by client, exercise, set number and side.
  Bilateral exercises use the side `"both"`; unilateral exercises carry a
  `"left"` and a `"right"` row for every set, and each side progresses on
  its own.
  """

  import Ecto.Query, warn: false

  alias Scopestrength.Repo
  alias Scopestrength.Progression
  alias Scopestrength.ClientProgressions.ClientProgression
  alias Scopestrength.Training.Workout
  alias Scopestrength.Training.WorkoutDetails

  @default_method "dynamic_double_progression"
  @default_min_reps 5
  @default_max_reps 10

  @doc """
  Processes one completed workout set.

  The set is matched to its progression using client, exercise, set number
  and side. The progression rules are handled by `Scopestrength.Progression`.
  """
  def process_workout_detail(client_id, %WorkoutDetails{} = workout_detail) do
    side = side_of(workout_detail)

    progression =
      get_progression(client_id, workout_detail.exercise_id, workout_detail.set, side) ||
        create_default_progression(client_id, workout_detail, side)

    if is_nil(progression) do
      :ignored
    else
      case Progression.evaluate(progression.progression_method, workout_detail, progression) do
        :ignored ->
          :ignored

        %{status: status, target_weight: target_weight} ->
          Repo.transaction(fn ->
            update_progression(progression, %{target_weight: target_weight, status: status})
            update_workout_detail_status(workout_detail, status)
            status
          end)
      end
    end
  end

  defp side_of(%WorkoutDetails{side: side}) when side in ["left", "right"], do: side
  defp side_of(_workout_detail), do: "both"

  defp create_default_progression(client_id, workout_detail, side) do
    attrs =
      case sibling_progression(client_id, workout_detail.exercise_id, side) do
        %ClientProgression{} = sibling ->
          %{
            progression_method: sibling.progression_method,
            min_reps: sibling.min_reps,
            max_reps: sibling.max_reps
          }

        nil ->
          %{
            progression_method: @default_method,
            min_reps: @default_min_reps,
            max_reps: @default_max_reps
          }
      end

    case %ClientProgression{}
         |> ClientProgression.changeset(
           Map.merge(attrs, %{
             client_id: client_id,
             exercise_id: workout_detail.exercise_id,
             set_number: workout_detail.set,
             side: side,
             target_weight: workout_detail.weight,
             status: "hold"
           })
         )
         |> Repo.insert() do
      {:ok, progression} -> progression
      {:error, _changeset} -> nil
    end
  end

  defp sibling_progression(client_id, exercise_id, side) do
    Repo.one(
      from c in ClientProgression,
        where: c.client_id == ^client_id and c.exercise_id == ^exercise_id,
        order_by: [desc: fragment("? = ?", c.side, ^side), desc: c.set_number],
        limit: 1
    )
  end

  defp update_progression(progression, attrs) do
    case progression |> ClientProgression.changeset(attrs) |> Repo.update() do
      {:ok, progression} -> progression
      {:error, changeset} -> Repo.rollback(changeset)
    end
  end

  defp update_workout_detail_status(workout_detail, status) do
    case workout_detail |> WorkoutDetails.changeset(%{progression_status: status}) |> Repo.update() do
      {:ok, workout_detail} -> workout_detail
      {:error, changeset} -> Repo.rollback(changeset)
    end
  end

  @doc """
  Seeds a client's progression from an assigned programme.

  Unilateral exercises get a left and a right row per set. Existing rows keep
  their status and receive the programme's method and rep range.
  """
  def seed_from_programme(client_id, programme) do
    rows = progression_rows(client_id, programme)

    Repo.transaction(fn ->
      Enum.reduce(rows, 0, fn attrs, written ->
        case get_progression(client_id, attrs.exercise_id, attrs.set_number, attrs.side) do
          nil ->
            case %ClientProgression{} |> ClientProgression.changeset(attrs) |> Repo.insert() do
              {:ok, _row} -> written + 1
              {:error, changeset} -> Repo.rollback(changeset)
            end

          existing ->
            attrs = Map.delete(attrs, :status)

            case existing |> ClientProgression.changeset(attrs) |> Repo.update() do
              {:ok, _row} -> written + 1
              {:error, changeset} -> Repo.rollback(changeset)
            end
        end
      end)
    end)
  end

  defp progression_rows(client_id, programme) do
    method = programme.progression_method

    programme.programmeTemplates
    |> Enum.flat_map(& &1.programmeDetails)
    |> Enum.flat_map(fn detail ->
      with true <- is_integer(detail.min_reps),
           true <- is_integer(detail.max_reps),
           set_count when set_count > 0 <- set_count(detail.set) do
        for set_number <- 1..set_count, side <- sides_for(detail) do
          %{
            client_id: client_id,
            exercise_id: detail.exercise_id,
            set_number: set_number,
            side: side,
            progression_method: method,
            min_reps: detail.min_reps,
            max_reps: detail.max_reps,
            target_weight: nil,
            status: "hold"
          }
        end
      else
        _ -> []
      end
    end)
    |> Enum.uniq_by(&{&1.exercise_id, &1.set_number, &1.side})
  end

  defp sides_for(%{exercise: %{is_unilateral: true}}), do: ["left", "right"]
  defp sides_for(_detail), do: ["both"]

  defp set_count(set) when is_binary(set) do
    case Integer.parse(String.trim(set)) do
      {count, _rest} when count > 0 -> count
      _ -> 0
    end
  end

  defp set_count(_set), do: 0

  @doc """
  Override the target weight and rep range across every set and side of one
  exercise. Each row's status is re-evaluated against its most recently
  logged set under the new rep range.

  Returns `{:ok, count}`, or `{:error, changeset}` if the values are invalid.
  """
  def update_exercise_progression(client_id, exercise_id, attrs) do
    Repo.transaction(fn ->
      client_id
      |> list_for_exercise(exercise_id)
      |> Enum.reduce(0, fn row, updated ->
        changeset = ClientProgression.changeset(row, attrs)

        changeset =
          case latest_workout_detail(client_id, exercise_id, row.set_number, row.side) do
            nil ->
              changeset

            workout_detail ->
              updated_progression = %{
                row
                | min_reps: Ecto.Changeset.get_field(changeset, :min_reps),
                  max_reps: Ecto.Changeset.get_field(changeset, :max_reps)
              }

              case Progression.evaluate(
                     updated_progression.progression_method,
                     workout_detail,
                     updated_progression
                   ) do
                %{status: status} -> Ecto.Changeset.put_change(changeset, :status, status)
                :ignored -> changeset
              end
          end

        case Repo.update(changeset) do
          {:ok, _row} -> updated + 1
          {:error, changeset} -> Repo.rollback(changeset)
        end
      end)
    end)
  end

  defp latest_workout_detail(client_id, exercise_id, set_number, side) do
    Repo.one(
      from wd in WorkoutDetails,
        join: w in Workout,
        on: wd.workout_id == w.id,
        where:
          w.client_id == ^client_id and
            wd.exercise_id == ^exercise_id and
            wd.set == ^set_number and
            wd.side == ^side,
        order_by: [desc_nulls_last: w.date, desc: w.id],
        limit: 1
    )
  end

  @doc """
  Gets the progression for one client, exercise, set and side.
  """
  def get_progression(client_id, exercise_id, set_number, side \\ "both") do
    Repo.get_by(
      ClientProgression,
      client_id: client_id,
      exercise_id: exercise_id,
      set_number: set_number,
      side: side
    )
  end

  @doc """
  Returns every progression row for an exercise, ordered by set then side.
  """
  def list_for_exercise(client_id, exercise_id) do
    ClientProgression
    |> where([c], c.client_id == ^client_id and c.exercise_id == ^exercise_id)
    |> order_by([c], asc: c.set_number, asc: c.side)
    |> Repo.all()
  end

  @doc """
  Returns every progression row for an exercise with the exercise preloaded.
  """
  def get_client_progression_with_exercise(client_id, exercise_id) do
    ClientProgression
    |> where([c], c.client_id == ^client_id and c.exercise_id == ^exercise_id)
    |> order_by([c], asc: c.set_number, asc: c.side)
    |> preload(:exercise)
    |> Repo.all()
  end

  def list_client_progression do
    Repo.all(ClientProgression)
  end

  def get_client_progression!(id) do
    Repo.get!(ClientProgression, id)
  end

  def create_client_progression(attrs \\ %{}) do
    %ClientProgression{}
    |> ClientProgression.changeset(attrs)
    |> Repo.insert()
  end

  def update_client_progression(%ClientProgression{} = client_progression, attrs) do
    client_progression
    |> ClientProgression.changeset(attrs)
    |> Repo.update()
  end

  def delete_client_progression(%ClientProgression{} = client_progression) do
    Repo.delete(client_progression)
  end

  def change_client_progression(%ClientProgression{} = client_progression, attrs \\ %{}) do
    ClientProgression.changeset(client_progression, attrs)
  end
end
