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

defmodule Scopestrength.Training do
  @moduledoc """
  The Training context.
  """

  import Ecto.Query, warn: false
  alias Scopestrength.Repo

  alias Scopestrength.Training.Workout

  @doc """
  Returns the list of workouts.

  ## Examples

      iex> list_workouts()
      [%Workout{}, ...]

  """
  def list_workouts do
    Repo.all(Workout)
  end

  @doc """
  Returns one client's most recent workouts, newest first, with their sets and
  each set's exercise preloaded.

  Workouts are dated by `date`, which older rows may leave blank, so ordering
  falls back to `inserted_at` the way `progress_summary/1` does.

  ## Examples

      iex> list_workouts_for_client(123, limit: 5)
      [%Workout{}, ...]

  """
  def list_workouts_for_client(client_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 10)

    details_query = from wd in Scopestrength.Training.WorkoutDetails, order_by: [asc: wd.set]

    Workout
    |> where([w], w.client_id == ^client_id)
    |> order_by([w], desc: fragment("COALESCE(?, ?)", w.date, w.inserted_at))
    |> limit(^limit)
    |> preload(workoutDetails: ^{details_query, [:exercise]})
    |> Repo.all()
  end

  @doc """
  Gets a single workout.

  Raises `Ecto.NoResultsError` if the Workout does not exist.

  ## Examples

      iex> get_workout!(123)
      %Workout{}

      iex> get_workout!(456)
      ** (Ecto.NoResultsError)

  """
  def get_workout!(id), do: Repo.get!(Workout, id)

  @doc """
  Creates a workout.

  ## Examples

      iex> create_workout(%{field: value})
      {:ok, %Workout{}}

      iex> create_workout(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_workout(attrs \\ %{}) do
    %Workout{}
    |> Workout.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a workout.

  ## Examples

      iex> update_workout(workout, %{field: new_value})
      {:ok, %Workout{}}

      iex> update_workout(workout, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_workout(%Workout{} = workout, attrs) do
    workout
    |> Workout.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a workout.

  ## Examples

      iex> delete_workout(workout)
      {:ok, %Workout{}}

      iex> delete_workout(workout)
      {:error, %Ecto.Changeset{}}

  """
  def delete_workout(%Workout{} = workout) do
    Repo.delete(workout)
  end

  @doc """
  Creates a workout and its sets for one client, in a single transaction.

  A workout whose sets failed to insert is worse than no workout at all -- it
  reads as a session where nothing was lifted -- so the two are written
  together or not at all.

  `sets` is a list of maps accepted by `WorkoutDetails.changeset/2`; each is
  scoped to the new workout automatically.

  ## Examples

      iex> create_workout_with_sets(%{client_id: 3, name: "Lower"}, [
      ...>   %{exercise_id: 17, set: 1, reps: 5, weight: 100.0}
      ...> ])
      {:ok, %Workout{}}

  """
  def create_workout_with_sets(workout_attrs, sets) when is_list(sets) do
    Repo.transaction(fn ->
      with {:ok, workout} <- create_workout(workout_attrs),
           :ok <- insert_sets(workout, sets) do
        get_workout_with_sets(workout.id)
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  defp insert_sets(workout, sets) do
    Enum.reduce_while(sets, :ok, fn attrs, :ok ->
      attrs = Map.put(attrs, :workout_id, workout.id)

      case create_workout_details(attrs) do
        {:ok, _} -> {:cont, :ok}
        {:error, changeset} -> {:halt, {:error, changeset}}
      end
    end)
  end

  @doc """
  Loads one workout with its sets and each set's exercise.
  """
  def get_workout_with_sets(id) do
    details_query = from wd in Scopestrength.Training.WorkoutDetails, order_by: [asc: wd.set]

    Workout
    |> where([w], w.id == ^id)
    |> preload(workoutDetails: ^{details_query, [:exercise]})
    |> Repo.one()
  end

  @doc """
  Fetches a workout only if it belongs to `client_id`.

  Returns `{:error, :not_found}` for both a missing workout and one belonging
  to somebody else: a caller must not be able to tell the difference, or the
  API becomes a way to probe which workout ids exist.
  """
  def fetch_client_workout(client_id, id) do
    case Repo.get_by(Workout, id: id, client_id: client_id) do
      nil -> {:error, :not_found}
      workout -> {:ok, workout}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking workout changes.

  ## Examples

      iex> change_workout(workout)
      %Ecto.Changeset{data: %Workout{}}

  """
  def change_workout(%Workout{} = workout, attrs \\ %{}) do
    Workout.changeset(workout, attrs)
  end

  alias Scopestrength.Training.WorkoutDetails
  alias Scopestrength.Exercises.Exercise

  @doc """
  Returns the list of workout_details.

  ## Examples

      iex> list_workout_details()
      [%WorkoutDetails{}, ...]

  """
  def list_workout_details do
    Repo.all(WorkoutDetails)
  end

  @doc """
  Gets a single workout_details.

  Raises `Ecto.NoResultsError` if the Workout details does not exist.

  ## Examples

      iex> get_workout_details!(123)
      %WorkoutDetails{}

      iex> get_workout_details!(456)
      ** (Ecto.NoResultsError)

  """
  def get_workout_details!(id), do: Repo.get!(WorkoutDetails, id)

  @doc """
  Creates a workout_details.

  ## Examples

      iex> create_workout_details(%{field: value})
      {:ok, %WorkoutDetails{}}

      iex> create_workout_details(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_workout_details(attrs \\ %{}) do
    %WorkoutDetails{}
    |> WorkoutDetails.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a workout_details.

  ## Examples

      iex> update_workout_details(workout_details, %{field: new_value})
      {:ok, %WorkoutDetails{}}

      iex> update_workout_details(workout_details, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_workout_details(%WorkoutDetails{} = workout_details, attrs) do
    workout_details
    |> WorkoutDetails.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a workout_details.

  ## Examples

      iex> delete_workout_details(workout_details)
      {:ok, %WorkoutDetails{}}

      iex> delete_workout_details(workout_details)
      {:error, %Ecto.Changeset{}}

  """
  def delete_workout_details(%WorkoutDetails{} = workout_details) do
    Repo.delete(workout_details)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking workout_details changes.

  ## Examples

      iex> change_workout_details(workout_details)
      %Ecto.Changeset{data: %WorkoutDetails{}}

  """
  def change_workout_details(%WorkoutDetails{} = workout_details, attrs \\ %{}) do
    WorkoutDetails.changeset(workout_details, attrs)
  end

  @doc """
  Returns a progress summary for a client_id.
  """
  def progress_summary(client_id) do
    workouts_query =
      from w in Workout,
        where: w.client_id == ^client_id

    total_workouts = Repo.aggregate(workouts_query, :count, :id)

    last_workout =
      Repo.one(
        from w in workouts_query,
          order_by: [desc: fragment("COALESCE(?, ?)", w.date, w.inserted_at)],
          limit: 1
      )

    total_sets =
      Repo.aggregate(
        from(wd in WorkoutDetails,
          join: w in Workout,
          on: wd.workout_id == w.id,
          where: w.client_id == ^client_id
        ),
        :count,
        :id
      )

    pr =
      Repo.one(
        from wd in WorkoutDetails,
          join: w in Workout,
          on: wd.workout_id == w.id,
          join: e in Exercise,
          on: wd.exercise_id == e.id,
          where: w.client_id == ^client_id and not is_nil(wd.weight),
          order_by: [desc: wd.weight],
          limit: 1,
          select: %{
            weight: wd.weight,
            reps: wd.reps,
            exercise_name: e.name,
            date: wd.inserted_at
          }
      )

    {:ok,
     %{
       total_workouts: total_workouts,
       last_workout_at: last_workout && (last_workout.date || last_workout.inserted_at),
       total_sets: total_sets,
       pr: pr
     }}
  end
end
