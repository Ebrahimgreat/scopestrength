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

defmodule Scopestrength.ClientNote do
  @moduledoc """
  The ClientNote context.
  """

  import Ecto.Query, warn: false
  alias Scopestrength.Repo

  alias Scopestrength.ClientNote.ClientNotes

  @doc """
  Returns the list of client_notes.

  ## Examples

      iex> list_client_notes()
      [%ClientNotes{}, ...]

  """
  def list_client_notes do
    Repo.all(ClientNotes)
  end

  @doc """
  Gets a single client_notes.

  Raises `Ecto.NoResultsError` if the Client notes does not exist.

  ## Examples

      iex> get_client_notes!(123)
      %ClientNotes{}

      iex> get_client_notes!(456)
      ** (Ecto.NoResultsError)

  """
  def get_client_notes!(id), do: Repo.get!(ClientNotes, id)

  @doc """
  Creates a client_notes.

  ## Examples

      iex> create_client_notes(%{field: value})
      {:ok, %ClientNotes{}}

      iex> create_client_notes(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_client_notes(attrs \\ %{}) do
    %ClientNotes{}
    |> ClientNotes.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a client_notes.

  ## Examples

      iex> update_client_notes(client_notes, %{field: new_value})
      {:ok, %ClientNotes{}}

      iex> update_client_notes(client_notes, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_client_notes(%ClientNotes{} = client_notes, attrs) do
    client_notes
    |> ClientNotes.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a client_notes.

  ## Examples

      iex> delete_client_notes(client_notes)
      {:ok, %ClientNotes{}}

      iex> delete_client_notes(client_notes)
      {:error, %Ecto.Changeset{}}

  """
  def delete_client_notes(%ClientNotes{} = client_notes) do
    Repo.delete(client_notes)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking client_notes changes.

  ## Examples

      iex> change_client_notes(client_notes)
      %Ecto.Changeset{data: %ClientNotes{}}

  """
  def change_client_notes(%ClientNotes{} = client_notes, attrs \\ %{}) do
    ClientNotes.changeset(client_notes, attrs)
  end
end
