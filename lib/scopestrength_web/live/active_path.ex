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

defmodule ScopestrengthWeb.ActivePath do
  @moduledoc """
  LiveView on_mount hook that keeps `@active_path` in sync with the current URL.

  The sidebar needs to know which nav item to highlight. LiveView navigation
  doesn't remount, so this attaches to `handle_params` rather than assigning
  once at mount.

  Usage:
      on_mount ScopestrengthWeb.ActivePath
  """

  import Phoenix.LiveView
  import Phoenix.Component

  def on_mount(:default, _params, _session, socket) do
    {:cont,
     socket
     |> assign_new(:active_path, fn -> nil end)
     |> attach_hook(:active_path, :handle_params, &set_active_path/3)}
  end

  defp set_active_path(_params, url, socket) do
    {:cont, assign(socket, :active_path, URI.parse(url).path)}
  end
end
