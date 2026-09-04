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

defmodule ScopestrengthWeb.Client.StrengthProgress do
  alias Scopestrength.Training.Workout
  alias Scopestrength.Training.WorkoutDetails
  alias Scopestrength.Repo
  alias Scopestrength.ClientProgressions
  use ScopestrengthWeb, :live_view
  import Ecto.Query

  defp top_set(sets) do
    Enum.max_by(sets, fn s -> {s.weight || 0, s.reps || 0} end)
  end

  def mount(params, _session, socket) do
    exercise_id = String.to_integer(params["exercise_id"])
    user = socket.assigns.current_user
    client = Repo.get_by(Scopestrength.Clients.Client, %{user_id: user.id})
    exercise_progression= ClientProgressions.get_client_progression_with_exercise(client.id,exercise_id)

    workout_details =
      Repo.all(
        from wd in WorkoutDetails,
          join: w in Workout,
          on: wd.workout_id == w.id,
          where: w.client_id == ^client.id and wd.exercise_id == ^exercise_id,
          order_by: [asc: w.date, asc: wd.set],
          preload: :exercise,
          preload: :workout
      )

    {exercise_name, pr} =
      if length(workout_details) > 0 do
        pr = top_set(workout_details)
        {hd(workout_details).exercise.name, pr}
      else
        {"", nil}
      end

    sessions =
      workout_details
      |> Enum.group_by(& &1.workout.date)
      |> Enum.sort_by(&elem(&1, 0), {:desc, Date})
      |> Enum.map(fn {date, sets} ->
        best = top_set(sets)
        avg_reps = Float.round(Enum.sum(Enum.map(sets, &(&1.reps || 0))) / length(sets), 1)
        %{date: date, sets: sets, top_weight: best.weight, top_reps: best.reps, avg_reps: avg_reps}
      end)


    grouped_workouts =
      sessions
      |> Enum.with_index()
      |> Enum.map(fn {session, idx} ->
        prev = Enum.at(sessions, idx + 1)
        Map.put(session, :prev, prev)
      end)

    overall_avg_reps =
      if length(workout_details) > 0 do
        Float.round(Enum.sum(Enum.map(workout_details, &(&1.reps || 0))) / length(workout_details), 1)
      else
        0.0
      end

    {:ok,
     assign(socket,
       exercise_name: exercise_name,
       pr: pr,
       grouped_workouts: grouped_workouts,
       overall_avg_reps: overall_avg_reps,
       exercise_progression: exercise_progression,
       last_session: List.first(sessions),
       client_id: client.id,
       exercise_id: exercise_id,
       progression_form: progression_form(exercise_progression)
     )}
  end

  defp progression_form([]), do: nil

  defp progression_form([first | _rest]) do
    first
    |> ClientProgressions.change_client_progression()
    |> to_form()
  end

  def handle_event("update_progression", %{"client_progression" => params}, socket) do
    attrs = Map.take(params, ["target_weight", "min_reps", "max_reps"])

    case ClientProgressions.update_exercise_progression(
           socket.assigns.client_id,
           socket.assigns.exercise_id,
           attrs
         ) do
      {:ok, _count} ->
        rows =
          ClientProgressions.get_client_progression_with_exercise(
            socket.assigns.client_id,
            socket.assigns.exercise_id
          )

        {:noreply,
         socket
         |> put_flash(:info, "Progression updated")
         |> assign(exercise_progression: rows, progression_form: progression_form(rows))}

      {:error, changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Check the weight and rep range")
         |> assign(:progression_form, to_form(changeset))}
    end
  end

  defp logged_set(nil, _set_number, _side), do: nil

  defp logged_set(session, set_number, side) do
    Enum.find(session.sets, &(&1.set == set_number and (&1.side || "both") == side))
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-4xl px-4 py-6 sm:px-6 lg:px-8">

      <div class="mb-6 flex items-center justify-between">
        <div>
          <h1 class="text-2xl font-semibold text-foreground"><%= @exercise_name %></h1>
          <p class="mt-1 text-sm text-dim">Strength Progress</p>
        </div>
        <.link navigate={~p"/client"} class="text-sm font-medium text-dim hover:text-foreground">
          ← Back
        </.link>
      </div>

      <div :if={@exercise_progression != []} class="mb-6 overflow-hidden rounded-xl border border-line bg-card">
        <% first = hd(@exercise_progression) %>
        <div class="flex flex-wrap items-center justify-between gap-3 border-b border-line px-4 py-4 sm:px-6">
          <div class="flex flex-wrap items-center gap-3">
            <h2 class="text-lg font-semibold text-foreground">Double Progression</h2>
            <span class="rounded-full border border-line px-3 py-1 text-xs uppercase tracking-widest text-dim">
              Reps first, then load
            </span>
          </div>
          <p class="text-sm text-dim">
            Target
            <span class="font-semibold text-foreground">
              <%= first.min_reps %>–<%= first.max_reps %> reps
            </span>
            on <%= length(@exercise_progression) %> sets
          </p>
        </div>

        <div class="p-4 sm:p-6">
          <p class="mb-4 text-xs uppercase tracking-widest text-dim">Last session — set by set</p>

          <div class="space-y-3">
            <%= for progression <- @exercise_progression do %>
              <% set = logged_set(@last_session, progression.set_number, progression.side) %>
              <div class="flex items-center gap-4">
                <span class="w-14 shrink-0 text-xs uppercase tracking-widest text-dim">
                  Set <%= progression.set_number %>
                  <span :if={progression.side != "both"} class="block text-faint"><%= progression.side %></span>
                </span>

                <div class="min-w-0 flex-1">
                  <p class="text-sm">
                    <%= if set do %>
                      <span class="text-base font-semibold text-foreground">
                        <%= progression.target_weight || set.weight || "BW" %><%= if progression.target_weight || set.weight do %>kg<% end %>
                      </span>
                      <span class="text-faint"> × </span>
                      <span class={[
                        "text-base font-semibold",
                        progression.status == "reduce" && "text-danger",
                        progression.status == "progress" && "text-primary",
                        progression.status not in ["reduce", "progress"] && "text-foreground"
                      ]}>
                        <%= set.reps || "—" %>
                      </span>
                      <span class="text-xs text-dim"> reps</span>
                    <% else %>
                      <span class="text-sm text-faint">Not logged yet</span>
                    <% end %>
                  </p>

                  <div class="mt-1.5 h-1.5 w-full overflow-hidden rounded-full bg-secondary">
                    <div
                      class={[
                        "h-full rounded-full",
                        progression.status == "reduce" && "bg-danger",
                        progression.status == "progress" && "bg-primary",
                        progression.status not in ["reduce", "progress"] && "bg-dim"
                      ]}
                      style={"width: #{if set && set.reps && progression.max_reps > 0, do: min(round(set.reps / progression.max_reps * 100), 100), else: 0}%"}
                    >
                    </div>
                  </div>
                </div>

                <span class={[
                  "shrink-0 rounded-full border px-3 py-1 text-xs font-medium uppercase tracking-wide",
                  progression.status == "reduce" && "border-danger/40 text-danger",
                  progression.status == "progress" && "border-primary/40 text-primary",
                  progression.status not in ["reduce", "progress"] && "border-line text-dim"
                ]}>
                  <%= progression.status %>
                </span>
              </div>
            <% end %>
          </div>

          <div class="mt-6 border-t border-line pt-5">
            <p class="mb-3 text-xs uppercase tracking-widest text-dim">
              Override — applies to all <%= length(@exercise_progression) %> sets
            </p>

            <.form for={@progression_form} phx-submit="update_progression" class="flex flex-wrap items-end gap-3">
              <div>
                <label class="mb-1 block text-xs text-dim">Working weight</label>
                <div class="flex items-center gap-1.5">
                  <input
                    type="text"
                    inputmode="decimal"
                    name={@progression_form[:target_weight].name}
                    value={@progression_form[:target_weight].value}
                    class="w-24 rounded-md border-line bg-muted px-3 py-2 text-center text-sm text-foreground focus:border-primary focus:ring-0"
                  />
                  <span class="text-sm text-dim">kg</span>
                </div>
              </div>

              <div>
                <label class="mb-1 block text-xs text-dim">Rep range</label>
                <div class="flex items-center gap-2">
                  <input
                    type="text"
                    inputmode="numeric"
                    name={@progression_form[:min_reps].name}
                    value={@progression_form[:min_reps].value}
                    class="w-16 rounded-md border-line bg-muted px-3 py-2 text-center text-sm text-foreground focus:border-primary focus:ring-0"
                  />
                  <span class="text-sm text-dim">to</span>
                  <input
                    type="text"
                    inputmode="numeric"
                    name={@progression_form[:max_reps].name}
                    value={@progression_form[:max_reps].value}
                    class="w-16 rounded-md border-line bg-muted px-3 py-2 text-center text-sm text-foreground focus:border-primary focus:ring-0"
                  />
                  <span class="text-sm text-dim">reps</span>
                </div>
              </div>

              <.button type="submit">Save</.button>
            </.form>
          </div>

          <div class="mt-5 flex gap-3 border-t border-line pt-4">
            <span class="shrink-0 text-xs uppercase tracking-widest text-dim">Rule</span>
            <p class="text-sm text-dim">
              Hit <%= first.max_reps %> reps on every set → add load and drop back to <%= first.min_reps %>.
              Inside the range → hold and add reps. Below <%= first.min_reps %> → cut the load.
            </p>
          </div>
        </div>
      </div>

      <%= if length(@grouped_workouts) == 0 do %>
        <div class="rounded-xl border border-dashed border-line bg-card p-8 text-center">
          <p class="text-dim">No workout data available for this exercise yet.</p>
        </div>
      <% else %>

        <div class="mb-6 grid grid-cols-2 gap-4 sm:grid-cols-4">
          <div class="rounded-xl border border-line bg-card p-4">
            <p class="text-xs font-medium text-dim">Personal Record</p>
            <p class="mt-1 text-2xl font-bold text-foreground">
              <%= if @pr.weight, do: @pr.weight, else: "—" %>
              <%= if @pr.weight do %><span class="text-sm font-normal text-dim">kg</span><% end %>
            </p>
          </div>
          <div class="rounded-xl border border-line bg-card p-4">
            <p class="text-xs font-medium text-dim">PR Reps</p>
            <p class="mt-1 text-2xl font-bold text-foreground">
              <%= if @pr.reps, do: @pr.reps, else: "—" %>
              <%= if @pr.reps do %><span class="text-sm font-normal text-dim">reps</span><% end %>
            </p>
          </div>
          <div class="rounded-xl border border-line bg-card p-4">
            <p class="text-xs font-medium text-dim">Avg Reps</p>
            <p class="mt-1 text-2xl font-bold text-foreground"><%= @overall_avg_reps %> <span class="text-sm font-normal text-dim">reps</span></p>
          </div>
          <div class="rounded-xl border border-line bg-card p-4">
            <p class="text-xs font-medium text-dim">Sessions</p>
            <p class="mt-1 text-2xl font-bold text-foreground"><%= length(@grouped_workouts) %></p>
          </div>
        </div>

        <div class="overflow-hidden rounded-xl border border-line bg-card">
          <div class="border-b border-line bg-card px-4 py-3 sm:px-6">
            <h2 class="text-sm font-semibold text-foreground">Session History</h2>
          </div>
          <div class="overflow-x-auto">
            <% max_sets = @grouped_workouts |> Enum.map(fn g -> length(g.sets) end) |> Enum.max() %>
            <table class="min-w-full divide-y divide-line">
              <thead>
                <tr class="bg-card">
                  <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-dim sm:px-6">
                    Date
                  </th>
                  <th class="px-4 py-3 text-center text-xs font-semibold uppercase tracking-wide text-dim">
                    Trend
                  </th>
                  <th class="px-4 py-3 text-center text-xs font-semibold uppercase tracking-wide text-dim">
                    Avg Reps
                  </th>
                  <%= for set_num <- 1..max_sets do %>
                    <th class="px-4 py-3 text-center text-xs font-semibold uppercase tracking-wide text-dim">
                      Set <%= set_num %>
                    </th>
                  <% end %>
                </tr>
              </thead>
              <tbody class="divide-y divide-line bg-card">
                <%= for session <- @grouped_workouts do %>
                  <tr class="hover:bg-card/70">
                    <td class="whitespace-nowrap px-4 py-3 text-sm font-medium text-foreground sm:px-6">
                      <%= Calendar.strftime(session.date, "%d %b %Y") %>
                    </td>
                    <td class="whitespace-nowrap px-4 py-3 text-center text-sm">
                      <%= cond do %>
                        <% session.prev == nil -> %>
                          <span class="text-gray-300 text-xs">—</span>
                        <% session.top_weight > session.prev.top_weight -> %>
                          <span class="inline-flex items-center gap-1 rounded-full bg-primary/10 px-2 py-0.5 text-xs font-medium text-primary ring-1 ring-primary/30">
                            ▲ +<%= Float.round(session.top_weight - session.prev.top_weight, 1) %>kg
                          </span>
                        <% session.top_weight < session.prev.top_weight -> %>
                          <span class="inline-flex items-center gap-1 rounded-full bg-danger/10 px-2 py-0.5 text-xs font-medium text-danger ring-1 ring-rose-200">
                            ▼ <%= Float.round(session.top_weight - session.prev.top_weight, 1) %>kg
                          </span>
                        <% session.top_reps > session.prev.top_reps -> %>
                          <span class="inline-flex items-center gap-1 rounded-full bg-primary/10 px-2 py-0.5 text-xs font-medium text-primary ring-1 ring-primary/30">
                            ▲ +<%= session.top_reps - session.prev.top_reps %> reps
                          </span>
                        <% session.top_reps < session.prev.top_reps -> %>
                          <span class="inline-flex items-center gap-1 rounded-full bg-danger/10 px-2 py-0.5 text-xs font-medium text-danger ring-1 ring-rose-200">
                            ▼ <%= session.top_reps - session.prev.top_reps %> reps
                          </span>
                        <% true -> %>
                          <span class="inline-flex items-center rounded-full bg-secondary px-2 py-0.5 text-xs font-medium text-dim">
                            = same
                          </span>
                      <% end %>
                    </td>
                    <td class="whitespace-nowrap px-4 py-3 text-center text-sm font-semibold text-foreground">
                      <%= session.avg_reps %>
                    </td>
                    <%= for set_num <- 1..max_sets do %>
                      <td class="whitespace-nowrap px-4 py-3 text-center text-sm text-foreground">
                        <%= case Enum.find(session.sets, &(&1.set == set_num)) do %>
                          <% nil -> %>
                            <span class="text-gray-200">—</span>
                          <% s -> %>
                            <span class="font-semibold"><%= s.weight || "BW" %><%= if s.weight do %>kg<% end %></span>
                            <span class="text-faint"> × </span>
                            <span><%= s.reps || "—" %></span>
                            <%= if s.side != "both" do %>
                              <div class="text-xs text-faint capitalize"><%= s.side %></div>
                            <% end %>
                        <% end %>
                      </td>
                    <% end %>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
