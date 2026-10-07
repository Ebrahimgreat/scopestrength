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

defmodule ScopestrengthWeb.Api.FallbackController do
  @moduledoc """
  Turns the error tuples returned by API actions into JSON responses.
  """

  use ScopestrengthWeb, :controller

  def call(conn, {:error, :bad_request}) do
    conn
    |> put_status(:bad_request)
    |> put_view(json: ScopestrengthWeb.Api.ClientJSON)
    |> render(:error, detail: "invalid parameter")
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(json: ScopestrengthWeb.Api.ClientJSON)
    |> render(:error, detail: "not found")
  end

  # A rejected changeset is the caller's fault, not the server's: without this
  # clause any validation failure escapes as a 500.
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: ScopestrengthWeb.Api.ClientJSON)
    |> render(:error, detail: changeset_message(changeset))
  end

  # Last resort, so an unexpected error term is still valid JSON rather than a
  # crash page.
  def call(conn, {:error, reason}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: ScopestrengthWeb.Api.ClientJSON)
    |> render(:error, detail: inspect(reason))
  end

  defp changeset_message(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map_join("; ", fn {field, msgs} ->
      "#{field}: #{Enum.join(List.wrap(msgs), ", ")}"
    end)
  end
end
