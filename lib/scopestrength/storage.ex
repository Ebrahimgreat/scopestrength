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

defmodule Scopestrength.Storage do
  @moduledoc """
  Uploaded file storage, behind a swappable adapter.

  A self-hosted install needs nothing configured: the default adapter writes
  to `priv/static/uploads` exactly as this app always has. Setting `S3_BUCKET`
  switches to object storage without touching application code.

  What goes in the database is a **key** -- `"progress_photos/<uuid>.jpg"` --
  never a URL. URLs are derived at render time by `url/1`, so the same rows
  work under either adapter, and switching adapters does not rewrite data.

  ## Adding a file

      {:ok, key} = Storage.put(tmp_path, "progress_photos", "abc.jpg")

  ## Showing it

      <img src={Storage.url(photo.photo_url)} />
  """

  @typedoc "Storage key, e.g. \"progress_photos/abc.jpg\". Not a URL."
  @type key :: String.t()

  @doc "Copies `source` (a local temp file) to `prefix/filename`, returning its key."
  @callback put(source :: Path.t(), prefix :: String.t(), filename :: String.t()) ::
              {:ok, key()} | {:error, term()}

  @doc "A URL a browser can fetch. May be short-lived for private backends."
  @callback url(key()) :: String.t()

  @doc "Removes the object. Missing objects are not an error."
  @callback delete(key()) :: :ok

  @doc """
  A URL the browser can PUT a file to directly, bypassing this server.

  Optional: only object-storage adapters can sign an upload. Local disk has no
  equivalent -- there is nowhere for a browser to PUT to -- so callers check
  `direct_upload?/0` and fall back to relaying through `put/3`.
  """
  @callback presigned_put(key(), content_type :: String.t()) ::
              {:ok, String.t()} | {:error, term()}

  @optional_callbacks presigned_put: 2

  @doc false
  def adapter do
    Application.get_env(:scopestrength, :storage, [])
    |> Keyword.get(:adapter, Scopestrength.Storage.Local)
  end

  @doc """
  Stores a file and returns its key.

  `filename` should already be unique -- callers use the upload entry's uuid.
  """
  @spec put(Path.t(), String.t(), String.t()) :: {:ok, key()} | {:error, term()}
  def put(source, prefix, filename), do: adapter().put(source, prefix, filename)

  @doc """
  Returns a browser-fetchable URL for a stored key.

  Passes `nil` through so templates can render optional images unguarded.
  Legacy values that are already a path or URL are returned unchanged, so rows
  written before this module existed keep working.
  """
  @spec url(key() | nil) :: String.t() | nil
  def url(nil), do: nil
  def url("http" <> _ = url), do: url
  def url("/" <> _ = legacy_path), do: legacy_path
  def url(key), do: adapter().url(key)

  @doc "Deletes a stored object. Safe to call with nil or a legacy path."
  @spec delete(key() | nil) :: :ok
  def delete(nil), do: :ok
  def delete(key), do: adapter().delete(key)

  @doc """
  Whether the current adapter can hand the browser a URL to upload to directly.

  True for object storage, false for local disk. Callers branch on this: a
  direct upload keeps large files off this server entirely, while the fallback
  relays them through `put/3` as before.
  """
  @spec direct_upload?() :: boolean()
  def direct_upload? do
    mod = adapter()
    Code.ensure_loaded?(mod) and function_exported?(mod, :presigned_put, 2)
  end

  @doc """
  Signs a URL the browser can PUT `key` to.

  Only meaningful when `direct_upload?/0` is true.
  """
  @spec presigned_put(key(), String.t()) :: {:ok, String.t()} | {:error, term()}
  def presigned_put(key, content_type) do
    if direct_upload?() do
      adapter().presigned_put(key, content_type)
    else
      {:error, :not_supported}
    end
  end
end
