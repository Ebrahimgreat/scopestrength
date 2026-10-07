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

defmodule ScopestrengthWeb.Plugs.ApiAuth do
  @moduledoc """
  Bearer-token authentication for the client API.

  Two kinds of token are accepted:

    * Database tokens (`sst_...`), issued from the API tokens page. These carry
      their own client, expiry and scope, and can be revoked individually.
    * A single static token configured as `:api_token` with `:api_user_email`.
      This predates the table and is kept so existing deployments keep working;
      new callers should be given a database token.

  Either way the connection ends up with `:current_user` and `:current_client`
  assigned, and every endpoint reads the client from there. No route accepts a
  client id, so a caller cannot ask for somebody else's data.
  """

  import Plug.Conn

  alias Scopestrength.Account
  alias Scopestrength.ApiTokens
  alias Scopestrength.Clients

  def init(opts), do: opts

  def call(conn, _opts) do
    with {:ok, presented} <- bearer_token(conn),
         {:ok, assigns} <- authenticate(presented) do
      conn
      |> assign(:current_user, assigns.user)
      |> assign(:current_client, assigns.client)
      |> assign(:api_token, assigns.token)
    else
      {:error, reason} -> deny(conn, reason)
    end
  end

  @doc """
  Resolves a presented token to its user, client and (for database tokens)
  token row. Shared with `ScopestrengthWeb.Plugs.McpAuth`, which takes the
  token from the URL rather than a header.

  Database tokens carry their own identity; the static token has to look its
  client up from config.
  """
  def authenticate("sst_" <> _ = presented) do
    case ApiTokens.verify_token(presented) do
      {:ok, token} ->
        {:ok, %{user: token.user, client: token.client, token: token}}

      # Never distinguish expired from revoked from unknown: that difference is
      # useful to an attacker and to nobody else.
      {:error, _reason} ->
        {:error, "invalid token"}
    end
  end

  def authenticate(presented) do
    with {:ok, configured} <- configured_token(),
         true <- Plug.Crypto.secure_compare(presented, configured),
         {:ok, user} <- configured_user(),
         {:ok, client} <- client_for(user) do
      {:ok, %{user: user, client: client, token: nil}}
    else
      false -> {:error, "invalid token"}
      {:error, reason} -> {:error, reason}
    end
  end

  defp configured_token do
    case Application.get_env(:scopestrength, :api_token) do
      token when is_binary(token) and token != "" -> {:ok, token}
      _ -> {:error, "invalid token"}
    end
  end

  defp configured_user do
    with email when is_binary(email) and email != "" <-
           Application.get_env(:scopestrength, :api_user_email),
         %Account.User{} = user <- Account.get_user_by_email(email) do
      {:ok, user}
    else
      nil -> {:error, "API user not found"}
      _ -> {:error, "API user not configured"}
    end
  end

  # Only a user who is a client has training data to read.
  defp client_for(user) do
    {:ok, Clients.get_client_byUserId(user.id)}
  rescue
    Ecto.NoResultsError -> {:error, "no client record for API user"}
  end

  defp bearer_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token | _] -> {:ok, String.trim(token)}
      _ -> {:error, "missing bearer token"}
    end
  end

  defp deny(conn, reason) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(401, Jason.encode!(%{errors: %{detail: reason}}))
    |> halt()
  end
end
