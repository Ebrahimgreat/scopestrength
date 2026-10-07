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

defmodule ScopestrengthWeb.Api.ClientController do
  @moduledoc """
  API over the signed-in client's own training data.

  The client comes from `conn.assigns.current_client`, set by
  `ScopestrengthWeb.Plugs.ApiAuth`. No action accepts a client id, so these
  endpoints can only ever touch the API user's own data: reads scope their
  queries to that client, and the one destructive action re-fetches by client
  before deleting rather than trusting the id in the path.
  """

  use ScopestrengthWeb, :controller

  alias Scopestrength.ClientProgressions
  alias Scopestrength.Exercise
  alias Scopestrength.Training

  action_fallback ScopestrengthWeb.Api.FallbackController

  @max_limit 50

  def summary(conn, _params) do
    {:ok, summary} = Training.progress_summary(conn.assigns.current_client.id)
    render(conn, :summary, summary: summary)
  end

  def workouts(conn, params) do
    workouts =
      Training.list_workouts_for_client(conn.assigns.current_client.id,
        limit: limit(params, 10)
      )

    render(conn, :workouts, workouts: workouts)
  end

  def exercises(conn, params) do
    exercises =
      Exercise.search_exercises_by_name(Map.get(params, "q", ""), limit: limit(params, 20))

    render(conn, :exercises, exercises: exercises)
  end

  def progressions(conn, %{"exercise_id" => exercise_id}) do
    with {:ok, id} <- integer_param(exercise_id) do
      progressions =
        ClientProgressions.get_client_progression_with_exercise(
          conn.assigns.current_client.id,
          id
        )

      render(conn, :progressions, progressions: progressions)
    end
  end

  @doc """
  Creates a workout with its sets, scoped to the current client.
  """
  def create_workout(conn, params) do
    client = conn.assigns.current_client

    with {:ok, sets} <- build_sets(params),
         workout_attrs <- %{
           client_id: client.id,
           name: Map.get(params, "name"),
           notes: Map.get(params, "notes"),
           date: parse_date(Map.get(params, "date"))
         },
         {:ok, workout} <- Training.create_workout_with_sets(workout_attrs, sets) do
      conn
      |> put_status(:created)
      |> render(:created_workout, workout: workout)
    end
  end

  @doc """
  Deletes one of the current client's workouts.

  The workout is re-fetched by client id first, so an id belonging to someone
  else is indistinguishable from one that does not exist.
  """
  def delete_workout(conn, %{"id" => id}) do
    with {:ok, workout_id} <- integer_param(id),
         {:ok, workout} <-
           Training.fetch_client_workout(conn.assigns.current_client.id, workout_id),
         {:ok, _deleted} <- Training.delete_workout(workout) do
      send_resp(conn, :no_content, "")
    end
  end

  # Sets arrive as a list from an LLM-driven caller, so every field is checked
  # here rather than trusted: a bad set should be a 400, not a changeset crash.
  defp build_sets(params) do
    case Map.get(params, "sets") do
      sets when is_list(sets) and sets != [] ->
        sets
        |> Enum.with_index(1)
        |> Enum.reduce_while({:ok, []}, fn {set, index}, {:ok, acc} ->
          case build_set(set, index) do
            {:ok, attrs} -> {:cont, {:ok, [attrs | acc]}}
            {:error, _} = error -> {:halt, error}
          end
        end)
        |> case do
          {:ok, acc} -> {:ok, Enum.reverse(acc)}
          error -> error
        end

      _ ->
        {:error, :bad_request}
    end
  end

  defp build_set(set, index) when is_map(set) do
    with {:ok, exercise_id} <- required_integer(set, "exercise_id") do
      {:ok,
       %{
         exercise_id: exercise_id,
         set: optional_integer(set, "set") || index,
         reps: optional_number(set, "reps"),
         weight: optional_number(set, "weight"),
         rir: optional_number(set, "rir"),
         rpe: optional_number(set, "rpe"),
         side: Map.get(set, "side") || "both"
       }}
    end
  end

  defp build_set(_set, _index), do: {:error, :bad_request}

  defp required_integer(map, key) do
    case Map.get(map, key) do
      value when is_integer(value) -> {:ok, value}
      value when is_binary(value) -> integer_param(value)
      _ -> {:error, :bad_request}
    end
  end

  defp optional_integer(map, key) do
    case Map.get(map, key) do
      value when is_integer(value) -> value
      value when is_binary(value) -> with {:ok, n} <- integer_param(value), do: n
      _ -> nil
    end
  end

  defp optional_number(map, key) do
    case Map.get(map, key) do
      value when is_number(value) -> value * 1.0
      value when is_binary(value) -> parse_float(value)
      _ -> nil
    end
  end

  defp parse_float(value) do
    case Float.parse(value) do
      {n, _} -> n
      :error -> nil
    end
  end

  defp parse_date(nil), do: DateTime.utc_now() |> DateTime.truncate(:second)

  defp parse_date(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, dt, _} -> DateTime.truncate(dt, :second)
      _ -> DateTime.utc_now() |> DateTime.truncate(:second)
    end
  end

  defp parse_date(_), do: DateTime.utc_now() |> DateTime.truncate(:second)

  # Keep an agent-supplied limit from asking for the whole table.
  defp limit(params, default) do
    case params |> Map.get("limit") |> parse_integer() do
      {:ok, n} when n > 0 -> min(n, @max_limit)
      _ -> default
    end
  end

  defp integer_param(value) do
    case parse_integer(value) do
      {:ok, n} -> {:ok, n}
      :error -> {:error, :bad_request}
    end
  end

  defp parse_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {n, ""} -> {:ok, n}
      _ -> :error
    end
  end

  defp parse_integer(_), do: :error
end
