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

defmodule Scopestrength.CustomExercises do
  @moduledoc """
  The CustomExercises context.
  """

  import Ecto.Query, warn: false
  alias Scopestrength.Repo

  alias Scopestrength.CustomExercises.CustomExercise

  @doc """
  Returns the list of custom_exercises.

  ## Examples

      iex> list_custom_exercises()
      [%CustomExercise{}, ...]

  """
  def list_custom_exercises do
    Repo.all(CustomExercise)
  end

  @doc """
  Gets a single custom_exercise.

  Raises `Ecto.NoResultsError` if the Custom exercise does not exist.

  ## Examples

      iex> get_custom_exercise!(123)
      %CustomExercise{}

      iex> get_custom_exercise!(456)
      ** (Ecto.NoResultsError)

  """
  def get_custom_exercise!(id), do: Repo.get!(CustomExercise, id)

  @doc """
  Creates a custom_exercise.

  ## Examples

      iex> create_custom_exercise(%{field: value})
      {:ok, %CustomExercise{}}

      iex> create_custom_exercise(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_custom_exercise(attrs \\ %{}) do
    %CustomExercise{}
    |> CustomExercise.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a custom_exercise.

  ## Examples

      iex> update_custom_exercise(custom_exercise, %{field: new_value})
      {:ok, %CustomExercise{}}

      iex> update_custom_exercise(custom_exercise, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_custom_exercise(%CustomExercise{} = custom_exercise, attrs) do
    custom_exercise
    |> CustomExercise.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a custom_exercise.

  ## Examples

      iex> delete_custom_exercise(custom_exercise)
      {:ok, %CustomExercise{}}

      iex> delete_custom_exercise(custom_exercise)
      {:error, %Ecto.Changeset{}}

  """
  def delete_custom_exercise(%CustomExercise{} = custom_exercise) do
    Repo.delete(custom_exercise)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking custom_exercise changes.

  ## Examples

      iex> change_custom_exercise(custom_exercise)
      %Ecto.Changeset{data: %CustomExercise{}}

  """
  def change_custom_exercise(%CustomExercise{} = custom_exercise, attrs \\ %{}) do
    CustomExercise.changeset(custom_exercise, attrs)
  end
end
