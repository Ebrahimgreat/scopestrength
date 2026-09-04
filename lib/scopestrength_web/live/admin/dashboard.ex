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

defmodule ScopestrengthWeb.Admin.Dashboard do
  use ScopestrengthWeb, :live_view
  alias Scopestrength.Repo
  import Ecto.Query

  def mount(_params, _session, socket) do
    leads = Repo.all(from l in Scopestrength.Leads.Lead, order_by: [desc: l.inserted_at])

    total_leads = length(leads)

    today = Date.utc_today()
    leads_today = Enum.count(leads, fn l ->
      Date.compare(DateTime.to_date(l.inserted_at), today) == :eq
    end)

    total_trainers = Repo.one(
      from u in Scopestrength.Account.User,
      where: u.role == "trainer" and u.type != "demo",
      select: count(u.id)
    )

    total_clients = Repo.one(
      from u in Scopestrength.Account.User,
      where: u.role == "client" and u.type != "demo",
      select: count(u.id)
    )

    {:ok, assign(socket,
      leads: leads,
      total_leads: total_leads,
      leads_today: leads_today,
      total_trainers: total_trainers,
      total_clients: total_clients
    )}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h1 class="text-2xl font-bold text-foreground">Dashboard</h1>

      <div class="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <div class="bg-card rounded-xl border border-line p-5 shadow-sm">
          <p class="text-xs font-medium text-dim uppercase tracking-wide">Total Leads</p>
          <p class="mt-2 text-3xl font-bold text-foreground">{@total_leads}</p>
          <p class="mt-1 text-xs text-faint">demo signups</p>
        </div>
        <div class="bg-card rounded-xl border border-line p-5 shadow-sm">
          <p class="text-xs font-medium text-dim uppercase tracking-wide">New Today</p>
          <p class="mt-2 text-3xl font-bold text-primary">{@leads_today}</p>
          <p class="mt-1 text-xs text-faint">leads today</p>
        </div>
        <div class="bg-card rounded-xl border border-line p-5 shadow-sm">
          <p class="text-xs font-medium text-dim uppercase tracking-wide">Trainers</p>
          <p class="mt-2 text-3xl font-bold text-foreground">{@total_trainers}</p>
          <p class="mt-1 text-xs text-faint">real accounts</p>
        </div>
        <div class="bg-card rounded-xl border border-line p-5 shadow-sm">
          <p class="text-xs font-medium text-dim uppercase tracking-wide">Clients</p>
          <p class="mt-2 text-3xl font-bold text-foreground">{@total_clients}</p>
          <p class="mt-1 text-xs text-faint">real accounts</p>
        </div>
      </div>

      <div class="bg-card rounded-xl border border-line shadow-sm overflow-hidden">
        <div class="px-6 py-4 border-b border-line flex items-center justify-between">
          <h2 class="text-base font-semibold text-foreground">Demo Leads</h2>
          <span class="text-xs text-faint">{@total_leads} total</span>
        </div>

        <div :if={@leads == []} class="px-6 py-12 text-center text-faint text-sm">
          No leads yet
        </div>

        <table :if={@leads != []} class="min-w-full divide-y divide-line">
          <thead class="bg-card">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-dim uppercase tracking-wider">Email</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-dim uppercase tracking-wider">Signed Up</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-dim uppercase tracking-wider">Time</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-line">
            <%= for lead <- @leads do %>
              <tr class="hover:bg-card transition-colors">
                <td class="px-6 py-4 text-sm font-medium text-foreground">
                  {lead.email}
                </td>
                <td class="px-6 py-4 text-sm text-dim">
                  {Calendar.strftime(lead.inserted_at, "%d %b %Y")}
                </td>
                <td class="px-6 py-4 text-sm text-faint">
                  {Calendar.strftime(lead.inserted_at, "%H:%M")}
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
    """
  end
end
