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

  Files live under `priv/static/uploads` and are served by the static plug at
  `/uploads`. Note this directory is **ephemeral in a container** unless it is
  mounted as a volume -- see the self-hosting notes in the README.
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
  def url(key), do: "/uploads/" <> key

  @impl true
  def delete(key) do
    relative = String.replace_prefix(key, "/uploads/", "")

    _ = File.rm(Path.join(root(), relative))
    :ok
  end

  defp root do
    Application.get_env(:scopestrength, :storage, [])
    |> Keyword.get(:local_root, Path.join(["priv", "static", "uploads"]))
  end
end
