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

defmodule ScopestrengthWeb.RequireRole do
  import Phoenix.LiveView

  @moduledoc """
  LiveView on_mount hook to enforce user roles.

  Usage:
      on_mount {ScopestrengthWeb.RequireRole, "trainer"}
      on_mount {ScopestrengthWeb.RequireRole, "client"}
  """

  def on_mount(role, _params, _session, socket) when is_binary(role) do
    case socket.assigns.current_user do
      nil ->
        {:halt, redirect(socket, to: "/users/log_in")}

      %{role: ^role} ->
        {:cont, socket}

      %{role: user_role} ->
        target = role_home(user_role)
        {:halt, push_navigate(socket, to: target)}
    end
  end

  defp role_home("trainer"), do: "/trainer"
  defp role_home("client"), do: "/client"
  defp role_home(_), do: "/users/log_in"
end
