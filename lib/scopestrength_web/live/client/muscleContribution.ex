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

defmodule ScopestrengthWeb.Client.MuscleContribution do
  alias Scopestrength.Repo
  alias Scopestrength.Clients
  alias Scopestrength.Training.WorkoutDetails
  alias Scopestrength.Training.Workout
  alias Scopestrength.Exercises.Exercise
  alias Scopestrength.Exercises.Muscles
  alias Scopestrength.Exercises.ExerciseMuscleContribution
  import Ecto.Query
  use ScopestrengthWeb, :live_view

  @page_size 5

  def mount(params, _session, socket) do
    muscle_id = String.to_integer(params["contribution"])
    user = socket.assigns.current_user
    client = Clients.get_client_byUserId(user.id)

    case Repo.get(Muscles, muscle_id) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Muscle not found")
         |> push_navigate(to: "/client")}

      muscle ->
        raw =
          Repo.all(
            from wd in WorkoutDetails,
              join: w in Workout, on: wd.workout_id == w.id,
              join: e in Exercise, on: wd.exercise_id == e.id,
              join: emc in ExerciseMuscleContribution, on: emc.exercise_id == e.id,
              where: w.client_id == ^client.id and emc.muscle_id == ^muscle_id,
              select: %{
                exercise_id: e.id,
                exercise_name: e.name,
                role: emc.role,
                multiplier: emc.multiplier,
                set: wd.set,
                reps: wd.reps,
                weight: wd.weight,
                date: w.date
              },
              order_by: [asc: emc.role, asc: e.name, desc: w.date, asc: wd.set]
          )

        exercises =
          raw
          |> Enum.group_by(& &1.role)
          |> Enum.into(%{}, fn {role, entries} ->
            by_exercise =
              entries
              |> Enum.group_by(& &1.exercise_name)
              |> Enum.into(%{}, fn {ex_name, ex_entries} ->
                exercise_id = List.first(ex_entries).exercise_id
                by_date =
                  ex_entries
                  |> Enum.group_by(&DateTime.to_date(&1.date))
                  |> Enum.sort_by(&elem(&1, 0), {:desc, Date})
                  |> Enum.map(fn {date, sets} ->
                    session_avg_reps = Float.round(Enum.sum(Enum.map(sets, & &1.reps)) / length(sets), 1)
                    weighted = Enum.filter(sets, &(&1.weight && &1.weight > 0))
                    session_avg_weight = if length(weighted) > 0, do: Float.round(Enum.sum(Enum.map(weighted, & &1.weight)) / length(weighted), 1), else: nil
                    {date, sets, session_avg_reps, session_avg_weight}
                  end)
                overall_avg_reps = Float.round(Enum.sum(Enum.map(ex_entries, & &1.reps)) / length(ex_entries), 1)
                weighted_all = Enum.filter(ex_entries, &(&1.weight && &1.weight > 0))
                overall_avg_weight = if length(weighted_all) > 0, do: Float.round(Enum.sum(Enum.map(weighted_all, & &1.weight)) / length(weighted_all), 1), else: nil
                {ex_name, {exercise_id, by_date, overall_avg_reps, overall_avg_weight}}
              end)
            {role, by_exercise}
          end)

        {:ok, socket |> assign(muscle: muscle, exercises: exercises, pages: %{})}
    end
  end

  def handle_event("next_page", %{"key" => key}, socket) do
    total = get_total_pages(socket.assigns.exercises, key)
    pages = socket.assigns.pages
    current = Map.get(pages, key, 0)
    {:noreply, assign(socket, pages: Map.put(pages, key, min(current + 1, total - 1)))}
  end

  def handle_event("prev_page", %{"key" => key}, socket) do
    pages = socket.assigns.pages
    current = Map.get(pages, key, 0)
    {:noreply, assign(socket, pages: Map.put(pages, key, max(current - 1, 0)))}
  end

  defp get_total_pages(exercises, key) do
    [role, exercise_name] = String.split(key, "||", parts: 2)
    {_exercise_id, by_date, _avg_reps, _avg_weight} = exercises |> Map.get(role, %{}) |> Map.get(exercise_name, {nil, [], nil, nil})
    ceil(length(by_date) / @page_size)
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-4xl px-4 py-6 sm:px-6 lg:px-8">
      <.back_link navigate={~p"/client/volumeTracking"}>Volume tracking</.back_link>
      <div class="mb-6">
        <h1 class="text-2xl font-semibold text-foreground"><%= @muscle.name %> Volume</h1>
        <p class="mt-1 text-sm text-dim">All exercises performed for this muscle group</p>
      </div>

      <%= if map_size(@exercises) == 0 do %>
        <div class="rounded-xl border border-dashed border-line bg-card p-8 text-center">
          <p class="text-dim">No exercises recorded for <%= @muscle.name %> yet.</p>
        </div>
      <% else %>
        <div class="space-y-8">
          <%= for {role, by_exercise} <- [{"primary", Map.get(@exercises, "primary", %{})}, {"secondary", Map.get(@exercises, "secondary", %{})}] do %>
            <%= if map_size(by_exercise) > 0 do %>
              <section>
                <h2 class={[
                  "mb-3 text-xs font-semibold uppercase tracking-wide",
                  if(role == "primary", do: "text-primary", else: "text-dim")
                ]}>
                  <%= if role == "primary", do: "Direct (Primary)", else: "Indirect (Secondary)" %>
                </h2>

                <div class="space-y-4">
                  <%= for {exercise_name, {exercise_id, by_date, overall_avg_reps, overall_avg_weight}} <- by_exercise |> Enum.sort_by(&elem(&1, 0)) do %>
                    <% key = "#{role}||#{exercise_name}" %>
                    <% current_page = Map.get(@pages, key, 0) %>
                    <% total_pages = ceil(length(by_date) / 5) %>
                    <% page_sessions = Enum.slice(by_date, current_page * 5, 5) %>

                    <div class="overflow-hidden rounded-xl border border-line bg-card">
                      <div class="flex items-center justify-between border-b border-line bg-card px-4 py-2.5">
                        <.link navigate={~p"/client/strengthProgress/#{exercise_id}"} class="text-sm font-semibold text-foreground hover:text-primary transition-colors">
                          <%= exercise_name %>
                        </.link>
                        <div class="flex items-center gap-3">
                          <span class="text-xs text-faint">avg <%= overall_avg_reps %> reps</span>
                          <%= if overall_avg_weight do %>
                            <span class="text-xs text-faint">avg <%= overall_avg_weight %>kg</span>
                          <% end %>
                          <span class="text-xs text-faint"><%= length(by_date) %> sessions</span>
                        </div>
                      </div>

                      <div class="divide-y divide-line">
                        <%= for {date, sets, session_avg_reps, session_avg_weight} <- page_sessions do %>
                          <div class="px-4 py-3">
                            <div class="mb-2 flex items-center gap-3">
                              <p class="text-xs font-medium text-dim">
                                <%= Calendar.strftime(date, "%b %d, %Y") %>
                              </p>
                              <span class="text-xs text-faint">avg <%= session_avg_reps %> reps<%= if session_avg_weight, do: " @ #{session_avg_weight}kg" %></span>
                            </div>
                            <div class="flex flex-wrap gap-2">
                              <%= for s <- sets do %>
                                <span class="inline-flex items-center rounded-full bg-secondary px-2.5 py-1 text-xs font-medium text-foreground">
                                  Set <%= s.set %>: <%= s.reps %> reps
                                  <%= if s.weight && s.weight > 0 do %>
                                    @ <%= s.weight %>kg
                                  <% end %>
                                </span>
                              <% end %>
                            </div>
                          </div>
                        <% end %>
                      </div>

                      <%= if total_pages > 1 do %>
                        <div class="flex items-center justify-between border-t border-line px-4 py-2.5">
                          <button
                            phx-click="prev_page"
                            phx-value-key={key}
                            disabled={current_page == 0}
                            class="text-xs font-medium text-dim hover:text-foreground disabled:opacity-30 disabled:cursor-not-allowed"
                          >
                            ← Previous
                          </button>
                          <span class="text-xs text-faint">
                            <%= current_page + 1 %> / <%= total_pages %>
                          </span>
                          <button
                            phx-click="next_page"
                            phx-value-key={key}
                            disabled={current_page + 1 >= total_pages}
                            class="text-xs font-medium text-dim hover:text-foreground disabled:opacity-30 disabled:cursor-not-allowed"
                          >
                            Next →
                          </button>
                        </div>
                      <% end %>
                    </div>
                  <% end %>
                </div>
              </section>
            <% end %>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

end
