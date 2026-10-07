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

defmodule ScopestrengthWeb.Plugs.McpAuth do
  @moduledoc """
  Authenticates requests to the MCP endpoint.

  The token is read from the `:token` path segment (`/mcp/<token>`) when
  present, because claude.ai custom connectors can only be given a URL. A
  client that can send headers may instead post to `/mcp` with
  `Authorization: Bearer <token>`.

  Identity resolution is shared with `ScopestrengthWeb.Plugs.ApiAuth`, so the
  same database tokens (and their scopes, expiry and revocation) apply.
  """

  import Plug.Conn

  alias ScopestrengthWeb.Plugs.ApiAuth

  def init(opts), do: opts

  def call(conn, _opts) do
    with {:ok, presented} <- presented_token(conn),
         {:ok, assigns} <- ApiAuth.authenticate(presented) do
      conn
      |> assign(:current_user, assigns.user)
      |> assign(:current_client, assigns.client)
      |> assign(:api_token, assigns.token)
    else
      {:error, _reason} -> deny(conn)
    end
  end

  defp presented_token(%{path_params: %{"token" => token}}) when token != "",
    do: {:ok, token}

  defp presented_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token | _] -> {:ok, String.trim(token)}
      _ -> {:error, :missing}
    end
  end

  # One answer for every failure, as in ApiAuth: a probe must not learn
  # whether a token exists, expired or was revoked.
  defp deny(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(
      401,
      Jason.encode!(%{
        jsonrpc: "2.0",
        id: nil,
        error: %{code: -32001, message: "invalid or missing token"}
      })
    )
    |> halt()
  end
end
