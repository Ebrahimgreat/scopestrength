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

defmodule ScopestrengthWeb.Plugs.RequireWriteScope do
  @moduledoc """
  Rejects a request that would change data unless its token allows writing.

  A token issued for reading should stay useless for creating or deleting
  workouts, so the two capabilities can be handed out separately.

  The static config token predates scopes and is treated as read-write, so
  existing deployments are not broken by this check.
  """

  import Plug.Conn

  alias Scopestrength.ApiTokens

  def init(opts), do: opts

  def call(%{assigns: %{api_token: nil}} = conn, _opts), do: conn

  def call(%{assigns: %{api_token: token}} = conn, _opts) do
    if ApiTokens.can_write?(token) do
      conn
    else
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(
        403,
        Jason.encode!(%{errors: %{detail: "this token is read-only"}})
      )
      |> halt()
    end
  end

  def call(conn, _opts), do: conn
end
