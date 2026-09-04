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

defmodule Scopestrength.Trainers do
  @moduledoc """
  The Trainers context.
  """

  import Ecto.Query, warn: false
  alias Scopestrength.Repo

  alias Scopestrength.Trainers.Trainer

  @spec list_trainers() :: any()
  @doc """
  Returns the list of trainers.

  ## Examples

      iex> list_trainers()
      [%Trainer{}, ...]

  """
  def list_trainers do
    Repo.all(Trainer)
  end

  @doc """
  Gets a single trainer.

  Raises `Ecto.NoResultsError` if the Trainer does not exist.

  ## Examples

      iex> get_trainer!(123)
      %Trainer{}

      iex> get_trainer!(456)
      ** (Ecto.NoResultsError)

  """

  def get_trainer_byUserId(user_id) do
    Repo.get_by!(Trainer, user_id: user_id)
  end
  def get_trainer!(id), do: Repo.get!(Trainer, id)

  @doc """
  Creates a trainer.

  ## Examples

      iex> create_trainer(%{field: value})
      {:ok, %Trainer{}}

      iex> create_trainer(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_trainer(attrs \\ %{}) do
    %Trainer{}
    |> Trainer.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a trainer.

  ## Examples

      iex> update_trainer(trainer, %{field: new_value})
      {:ok, %Trainer{}}

      iex> update_trainer(trainer, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_trainer(%Trainer{} = trainer, attrs) do
    trainer
    |> Trainer.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a trainer.

  ## Examples

      iex> delete_trainer(trainer)
      {:ok, %Trainer{}}

      iex> delete_trainer(trainer)
      {:error, %Ecto.Changeset{}}

  """
  def delete_trainer(%Trainer{} = trainer) do
    Repo.delete(trainer)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking trainer changes.

  ## Examples

      iex> change_trainer(trainer)
      %Ecto.Changeset{data: %Trainer{}}

  """
  def change_trainer(%Trainer{} = trainer, attrs \\ %{}) do
    Trainer.changeset(trainer, attrs)
  end
end
