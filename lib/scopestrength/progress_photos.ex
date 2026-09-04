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

defmodule Scopestrength.ProgressPhotos do
  @moduledoc """
  The ProgressPhotos context.
  """

  import Ecto.Query, warn: false
  alias Scopestrength.Repo

  alias Scopestrength.ProgressPhotos.ProgressPhoto

  @doc """
  Returns the list of progress_photos.

  ## Examples

      iex> list_progress_photos()
      [%ProgressPhoto{}, ...]

  """
  def list_progress_photos do
    Repo.all(ProgressPhoto)
  end

  @doc """
  Returns progress photos for a specific client, ordered by date descending.
  """
  def list_progress_photos_for_client(client_id) do
    from(p in ProgressPhoto,
      where: p.client_id == ^client_id,
      order_by: [desc: p.date]
    )
    |> Repo.all()
  end

  @doc """
  Gets a progress photo only if it belongs to the specified client.
  """
  def get_progress_photo_for_client!(id, client_id) do
    Repo.get_by!(ProgressPhoto, id: id, client_id: client_id)
  end

  @doc """
  Gets a single progress_photo.

  Raises `Ecto.NoResultsError` if the Progress photo does not exist.

  ## Examples

      iex> get_progress_photo!(123)
      %ProgressPhoto{}

      iex> get_progress_photo!(456)
      ** (Ecto.NoResultsError)

  """
  def get_progress_photo!(id), do: Repo.get!(ProgressPhoto, id)

  @doc """
  Creates a progress_photo.

  ## Examples

      iex> create_progress_photo(%{field: value})
      {:ok, %ProgressPhoto{}}

      iex> create_progress_photo(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_progress_photo(attrs \\ %{}) do
    %ProgressPhoto{}
    |> ProgressPhoto.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a progress_photo.

  ## Examples

      iex> update_progress_photo(progress_photo, %{field: new_value})
      {:ok, %ProgressPhoto{}}

      iex> update_progress_photo(progress_photo, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_progress_photo(%ProgressPhoto{} = progress_photo, attrs) do
    progress_photo
    |> ProgressPhoto.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a progress_photo.

  ## Examples

      iex> delete_progress_photo(progress_photo)
      {:ok, %ProgressPhoto{}}

      iex> delete_progress_photo(progress_photo)
      {:error, %Ecto.Changeset{}}

  """
  def delete_progress_photo(%ProgressPhoto{} = progress_photo) do
    Repo.delete(progress_photo)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking progress_photo changes.

  ## Examples

      iex> change_progress_photo(progress_photo)
      %Ecto.Changeset{data: %ProgressPhoto{}}

  """
  def change_progress_photo(%ProgressPhoto{} = progress_photo, attrs \\ %{}) do
    ProgressPhoto.changeset(progress_photo, attrs)
  end
end
