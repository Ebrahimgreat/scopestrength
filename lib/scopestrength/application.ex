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

defmodule Scopestrength.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    try do
      Scopestrength.Release.migrate()
    rescue
      e ->
        require Logger
        Logger.error("Auto-migration failed: #{inspect(e)}")
        :ok
    end

    children = [
      ScopestrengthWeb.Telemetry,
      Scopestrength.Repo,
      {Oban, Application.fetch_env!(:scopestrength, Oban)},
      {Phoenix.PubSub, name: Scopestrength.PubSub},
      {Finch, name: Scopestrength.Finch},
      ScopestrengthWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Scopestrength.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    ScopestrengthWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
