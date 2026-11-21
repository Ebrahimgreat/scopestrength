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

defmodule Scopestrength.Storage.Local do
  @moduledoc """
  Stores uploads on the local filesystem. This is the default, so a fresh
  self-hosted install works with nothing configured.

  Files live under `priv/uploads` and are served only through the authenticated
  file controller. Note this directory is **ephemeral in a container** unless
  it is mounted as a volume -- see the self-hosting notes in the README.
  """

  @behaviour Scopestrength.Storage

  @impl true
  def put(source, prefix, filename) do
    dir = Path.join(root(), prefix)
    File.mkdir_p!(dir)

    case File.cp(source, Path.join(dir, filename)) do
      :ok -> {:ok, Path.join(prefix, filename)}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def url(key), do: "/files/" <> key

  @impl true
  def delivery(key) do
    case path(key) do
      {:ok, file_path} -> {:file, file_path}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def delete(key) do
    case path(key) do
      {:ok, file_path} -> _ = File.rm(file_path)
      {:error, _reason} -> :ok
    end

    :ok
  end

  @doc false
  def path(key) when is_binary(key) do
    key = normalize_key(key)

    if key == nil or String.starts_with?(key, "/") do
      {:error, :invalid_key}
    else
      expanded_root = Path.expand(root())
      expanded_path = Path.expand(Path.join(expanded_root, key))

      if expanded_path == expanded_root or
           String.starts_with?(expanded_path, expanded_root <> Path.sep) do
        {:ok, expanded_path}
      else
        {:error, :invalid_key}
      end
    end
  end

  def path(_key), do: {:error, :invalid_key}

  defp normalize_key("/uploads/" <> key), do: key
  defp normalize_key("/files/" <> key), do: key
  defp normalize_key(key), do: key

  defp root do
    Application.get_env(:scopestrength, :storage, [])
    |> Keyword.get(:local_root, Path.join(["priv", "uploads"]))
  end
end
