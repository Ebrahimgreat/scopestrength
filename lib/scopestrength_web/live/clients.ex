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

defmodule ScopestrengthWeb.Clients do
  use ScopestrengthWeb, :live_view
  alias Scopestrength.Storage
  alias Scopestrength.Trainers
  alias Scopestrength.Clients

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    trainer = Trainers.get_trainer_byUserId(user.id)
    clients = Clients.get_clients_for_trainer(trainer.id)

    {:ok, assign(socket, clients: clients, trainer_id: trainer.id)}
  end



  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-5xl">
      <div class="flex flex-wrap items-end justify-between gap-4">
        <div>
          <p class="text-xs font-medium uppercase tracking-widest text-dim">Roster</p>
          <h1 class="mt-1 font-display text-5xl font-bold uppercase tracking-wide text-foreground">
            Clients
          </h1>
        </div>
        <span class="num shrink-0 text-sm text-dim"><%= length(@clients) %> total</span>
      </div>

      <div
        :if={@clients == []}
        class="mt-8 rounded-xl border border-dashed border-line px-6 py-16 text-center"
      >
        <h3 class="font-display text-xl font-bold uppercase tracking-wide text-foreground">
          No clients yet
        </h3>
        <p class="mx-auto mt-2 max-w-sm text-sm text-dim">
          Share an invite code to connect your first client.
        </p>
        <div class="mt-6">
          <.link
            navigate={~p"/trainer/invites"}
            class="text-sm font-medium text-primary transition hover:opacity-80"
          >
            Go to invites →
          </.link>
        </div>
      </div>

      <div :if={@clients != []} class="mt-8 overflow-hidden rounded-xl border border-line bg-card">
        <.link
          :for={client <- @clients}
          navigate={~p"/trainer/clients/#{client.id}"}
          class="flex items-center gap-4 border-b border-line/60 px-5 py-4 transition last:border-0 hover:bg-secondary/50"
        >
          <%= if client.profile_picture_url do %>
            <img
              src={Storage.url(client.profile_picture_url)}
              alt=""
              class="h-10 w-10 shrink-0 rounded-full border border-line object-cover"
            />
          <% else %>
            <div class="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-secondary text-sm font-bold text-primary">
              <%= String.first(client.user.name || "?") |> String.upcase() %>
            </div>
          <% end %>

          <div class="min-w-0 flex-1">
            <p class="truncate font-medium text-foreground"><%= client.user.name %></p>
            <p class="truncate text-xs text-dim"><%= client.user.email %></p>
          </div>

          <span class="hidden shrink-0 items-center gap-1.5 rounded-full bg-primary/10 px-2.5 py-1 text-xs font-medium text-primary sm:inline-flex">
            <span class="h-1.5 w-1.5 rounded-full bg-primary"></span> Active
          </span>

          <.icon name="hero-chevron-right" class="h-4 w-4 shrink-0 text-faint" />
        </.link>
      </div>
    </div>
    """
  end
end
