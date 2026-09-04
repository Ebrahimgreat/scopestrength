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

defmodule Scopestrength.Storage.S3 do
  @moduledoc """
  Stores uploads in an S3-compatible bucket (AWS S3, Cloudflare R2, Backblaze
  B2, MinIO, DigitalOcean Spaces).

  The bucket is expected to be **private**. Files are served through presigned
  URLs that expire, so a leaked link stops working and progress photos are not
  world-readable. Because the URL changes per render, only the key is stored.

  Enabled by setting `S3_BUCKET`; see `config/runtime.exs`.
  """

  @behaviour Scopestrength.Storage

  @url_expires_in_seconds 3600

  @impl true
  def put(source, prefix, filename) do
    key = Path.join(prefix, filename)

    with {:ok, body} <- File.read(source),
         {:ok, _} <-
           bucket()
           |> ExAws.S3.put_object(key, body, content_type: content_type(filename))
           |> ExAws.request() do
      {:ok, key}
    end
  end

  @impl true
  def url(key) do
    config = ExAws.Config.new(:s3)

    case ExAws.S3.presigned_url(config, :get, bucket(), key,
           expires_in: @url_expires_in_seconds
         ) do
      {:ok, url} -> url
      {:error, _reason} -> nil
    end
  end

  @impl true
  def delete(key) do
    bucket() |> ExAws.S3.delete_object(key) |> ExAws.request()
    :ok
  end

  @upload_expires_in_seconds 900

  @impl true
  def presigned_put(key, content_type) do
    ExAws.Config.new(:s3)
    |> ExAws.S3.presigned_url(:put, bucket(), key,
      expires_in: @upload_expires_in_seconds,
      query_params: [{"Content-Type", content_type}]
    )
  end

  defp bucket do
    Application.get_env(:scopestrength, :storage, [])
    |> Keyword.fetch!(:bucket)
  end

  defp content_type(filename) do
    case filename |> Path.extname() |> String.downcase() do
      ".jpg" -> "image/jpeg"
      ".jpeg" -> "image/jpeg"
      ".png" -> "image/png"
      ".gif" -> "image/gif"
      ".webp" -> "image/webp"
      ".heic" -> "image/heic"
      ".pdf" -> "application/pdf"
      _ -> "application/octet-stream"
    end
  end
end
