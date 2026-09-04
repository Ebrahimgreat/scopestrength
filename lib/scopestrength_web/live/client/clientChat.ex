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

defmodule ScopestrengthWeb.ClientChat do
  alias Scopestrength.Clients.Client
  alias Scopestrength.Repo
  use ScopestrengthWeb, :live_view

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    client = Repo.get_by(Client, %{user_id: user.id}) |> Repo.preload(:trainer)
    trainer = client && client.trainer

    {:ok, assign(socket, client: client, trainer: trainer)}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto p-4">
      <h1 class="text-xl font-semibold text-foreground mb-4">Messages</h1>

      <%= if @trainer do %>
        <div class="bg-card border border-line rounded-lg">
          <.link navigate={~p"/chat/#{@client.id}"} class="block hover:bg-card transition-colors">
            <div class="flex items-center px-4 py-3">
              <div class="flex-shrink-0">
                <div class="h-10 w-10 rounded-full bg-secondary flex items-center justify-center text-foreground font-semibold text-sm">
                  T
                </div>
              </div>
              <div class="ml-4 flex-1">
                <p class="text-sm font-medium text-foreground">Your Trainer</p>
                <p class="text-xs text-dim">Tap to chat</p>
              </div>
            </div>
          </.link>
        </div>
      <% else %>
        <div class="text-center py-12 text-dim">
          <p class="text-base font-medium text-foreground">No trainer assigned</p>
          <p class="mt-1 text-sm">You'll be able to chat once a trainer is assigned to you.</p>
        </div>
      <% end %>
    </div>
    """
  end
end
