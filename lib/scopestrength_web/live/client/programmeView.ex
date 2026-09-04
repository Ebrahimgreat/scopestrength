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

defmodule ScopestrengthWeb.Client.ProgrammeView do
  use ScopestrengthWeb, :live_view

  alias Scopestrength.Clients.Client
  alias Scopestrength.Programmes.ProgrammeUser
  alias Scopestrength.Repo

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    client = Repo.get_by(Client, %{user_id: user.id})

    current_programme =
      Repo.get_by(ProgrammeUser, %{client_id: client.id})
      |> case do
        nil -> nil
        pu -> Repo.preload(pu, [programme: [programmeTemplates: [programmeDetails: :exercise]]])
      end

    muscle_group_volume =
      case current_programme do
        nil -> %{}
        programme_user ->
          programme_user.programme.programmeTemplates
          |> Enum.flat_map(fn template -> template.programmeDetails end)
          |> Enum.group_by(fn detail -> if detail.exercise.muscle, do: detail.exercise.muscle.name, else: "Unknown" end)
          |> Enum.map(fn {muscle_group, details} ->
            total_sets = details
              |> Enum.map(&String.to_integer(&1.set))
              |> Enum.sum()
            {muscle_group, total_sets}
          end)
          |> Map.new()
      end

    template_volumes =
      case current_programme do
        nil -> %{}
        programme_user ->
          programme_user.programme.programmeTemplates
          |> Enum.map(fn template ->
            volume = template.programmeDetails
              |> Enum.group_by(fn detail -> if detail.exercise.muscle, do: detail.exercise.muscle.name, else: "Unknown" end)
              |> Enum.map(fn {muscle_group, details} ->
                total_sets = details
                  |> Enum.map(&String.to_integer(&1.set))
                  |> Enum.sum()
                {muscle_group, total_sets}
              end)
              |> Map.new()
            {template.id, volume}
          end)
          |> Map.new()
      end

    {:ok, assign(socket,
      current_programme: current_programme,
      muscle_group_volume: muscle_group_volume,
      template_volumes: template_volumes
    )}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto px-4 py-6 space-y-6">
      <div class="flex items-center space-x-3">
        <.link
          navigate={~p"/client"}
          class="inline-flex items-center text-sm text-dim hover:text-foreground transition-colors"
        >
          <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
          </svg>
          Back
        </.link>
        <h1 class="text-2xl font-bold text-foreground">My Programme</h1>
      </div>

      <%= if @current_programme do %>
        <div class="bg-card rounded-xl shadow-sm border border-line overflow-hidden">
          <div class="px-5 py-4 border-b border-line">
            <h2 class="text-lg font-semibold text-foreground"><%= @current_programme.programme.name %></h2>
            <%= if @current_programme.programme.description do %>
              <p class="text-sm text-dim mt-1"><%= @current_programme.programme.description %></p>
            <% end %>
          </div>
        </div>

        <%= if map_size(@muscle_group_volume) > 0 do %>
          <div class="bg-card rounded-xl shadow-sm border border-line overflow-hidden">
            <div class="px-5 py-4 border-b border-line">
              <h2 class="text-lg font-semibold text-foreground">Weekly Muscle Group Volume</h2>
              <p class="text-sm text-dim mt-1">Total sets per muscle group across all sessions</p>
            </div>
            <div class="p-4">
              <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-3">
                <%= for {muscle_group, total_sets} <- @muscle_group_volume do %>
                  <div class="bg-muted border border-line rounded-lg px-3 py-2.5">
                    <p class="text-xs font-semibold text-foreground truncate"><%= muscle_group %></p>
                    <div class="flex items-center justify-between mt-2 text-[11px] text-dim">
                      <span>Total Sets</span>
                      <span class="inline-flex items-center justify-center px-2 py-0.5 bg-gradient-to-r from-orange-500 to-amber-500 text-foreground text-xs font-semibold rounded-full">
                        <%= total_sets %>
                      </span>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        <% end %>

        <div class="space-y-4">
          <%= for template <- @current_programme.programme.programmeTemplates do %>
            <div class="bg-card rounded-xl shadow-sm border border-line overflow-hidden">
              <div class="px-5 py-4 bg-card border-b border-line">
                <h3 class="font-semibold text-foreground"><%= template.name %></h3>
              </div>

              <%= if Map.has_key?(@template_volumes, template.id) and map_size(@template_volumes[template.id]) > 0 do %>
                <div class="px-5 py-3 border-b border-line bg-warning/10">
                  <p class="text-xs font-semibold text-dim mb-2">Session Volume</p>
                  <div class="flex flex-wrap gap-2">
                    <%= for {muscle_group, total_sets} <- @template_volumes[template.id] do %>
                      <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-warning/10 text-warning">
                        <%= muscle_group %>: <%= total_sets %> sets
                      </span>
                    <% end %>
                  </div>
                </div>
              <% end %>

              <div class="divide-y divide-line">
                <%= for detail <- template.programmeDetails do %>
                  <div class="px-5 py-3 flex items-center justify-between">
                    <div>
                      <span class="font-medium text-foreground"><%= detail.exercise.name %></span>
                      <span class="ml-2 text-xs text-faint"><%= if detail.exercise.muscle, do: detail.exercise.muscle.name, else: "N/A" %></span>
                    </div>
                    <div class="flex items-center space-x-4 text-sm text-dim">
                      <span class="px-2 py-0.5 bg-primary/10 text-primary rounded text-xs font-medium"><%= detail.set %> sets</span>
                      <span class="px-2 py-0.5 bg-primary/10 text-primary rounded text-xs font-medium"><%= detail.reps %> reps</span>
                      <%= if detail.rir do %>
                        <span class="px-2 py-0.5 bg-secondary text-dim rounded text-xs font-medium">RIR <%= detail.rir %></span>
                      <% end %>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>

      <% else %>
        <div class="bg-card rounded-xl p-8 text-center border border-line">
          <div class="w-16 h-16 bg-secondary rounded-full flex items-center justify-center mx-auto mb-3">
            <svg class="w-8 h-8 text-faint" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
            </svg>
          </div>
          <p class="text-dim font-medium">No programme assigned yet</p>
          <p class="text-sm text-faint mt-1">Your trainer will assign a programme soon</p>
        </div>
      <% end %>
    </div>
    """
  end
end
