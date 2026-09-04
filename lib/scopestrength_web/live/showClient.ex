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

defmodule ScopestrengthWeb.ShowClient do
  alias Scopestrength.Training.Workout
  alias Scopestrength.Trainers
  alias Scopestrength.Clients.Client
  alias Scopestrength.Repo
  alias Scopestrength.Programmes.ProgrammeUser
  import Ecto.Query
  use ScopestrengthWeb, :live_view

  def mount(params, _session, socket) do
    user = socket.assigns.current_user
    trainer = Trainers.get_trainer_byUserId(user.id)

    id = String.to_integer(params["id"])

    case Repo.get(Client, id) |> Repo.preload(:user) do
      nil ->
        {:ok, socket |> put_flash(:error, "Client Not found") |> redirect(to: "/clients")}

      client ->
        case client.trainer_id == trainer.id do
          true ->
            programmeUser =
              Repo.get_by(ProgrammeUser, client_id: client.id, is_active: true)
              |> Repo.preload(:programme)

            notifications =
              Repo.all(
                from n in Scopestrength.Notifications.Notification,
                where: n.actor_type == "client" and n.actor_id == ^client.user.id,
                order_by: [desc: n.inserted_at],
                limit: 10
              )

            exercise_progress_list =
              Repo.all(
                from wd in Scopestrength.Training.WorkoutDetails,
                  join: w in Workout, on: wd.workout_id == w.id,
                  where: w.client_id == ^client.id,
                  join: e in assoc(wd, :exercise),
                  group_by: [e.id, e.name],
                  order_by: [asc: e.name],
                  select: %{exercise_id: e.id, name: e.name, total_sets: count(wd.id)}
              )

            {:ok, assign(socket, programmeUser: programmeUser, client: client, notifications: notifications, exercise_progress_list: exercise_progress_list)}

          false ->
            {:ok, socket |> put_flash(:error, "Client Does not Exist")}
        end
    end
  end

  def render(assigns) do
    ~H"""
    <div class="w-full min-h-screen bg-card">
      <div class="w-full px-0 sm:px-2 lg:px-4 pt-10 pb-6">
        <div class="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
          <div class="flex items-center gap-3 lg:gap-4">
            <.link
              navigate={~p"/trainer/clients"}
              class="inline-flex h-10 w-10 shrink-0 items-center justify-center rounded-lg border border-line text-dim transition-colors hover:bg-secondary hover:text-foreground"
              aria-label="Back to clients"
            >
              <.icon name="hero-arrow-left" class="h-5 w-5" />
            </.link>
            <div>
              <h1 class="text-3xl lg:text-4xl font-semibold tracking-tight text-foreground">
                {@client.user.name}
              </h1>
              <p class="mt-2 text-dim text-base lg:text-lg">Client Profile & Management</p>
            </div>
          </div>
          <div class="flex items-center gap-3">
            <a
              href={~p"/download/client-report/#{@client.id}"}
              class="inline-flex items-center px-4 py-2 bg-primary hover:opacity-90 text-primary-foreground font-medium rounded-lg transition-colors"
            >
              <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
              Generate Report
            </a>
          </div>
        </div>
      </div>

      <div class="w-full px-0 sm:px-2 lg:px-4 pb-10">
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 lg:gap-8">

          <div class="bg-card border border-line rounded-2xl shadow-sm overflow-hidden">
            <div class="px-5 py-4 border-b border-line">
              <h2 class="text-base font-semibold text-foreground">Client Information</h2>
              <p class="text-xs text-dim mt-1">Client details and personal information</p>
            </div>
            <div class="p-5 space-y-4">
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label class="block text-xs font-medium text-foreground mb-1">Full Name</label>
                  <p class="text-sm font-medium text-foreground">{@client.user.name}</p>
                </div>
                <div>
                  <label class="block text-xs font-medium text-foreground mb-1">Age</label>
                  <p class="text-sm font-medium text-foreground">{@client.age || "Not specified"}</p>
                </div>
              </div>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label class="block text-xs font-medium text-foreground mb-1">Height (cm)</label>
                  <p class="text-sm font-medium text-foreground">
                    {@client.height || "Not specified"}
                  </p>
                </div>
                <div>
                  <label class="block text-xs font-medium text-foreground mb-1">Gender</label>
                  <p class="text-sm font-medium text-foreground">
                    {String.capitalize(@client.sex || "Not specified")}
                  </p>
                </div>
              </div>
              <div>
                <label class="block text-xs font-medium text-foreground mb-1">Notes</label>
                <p class="text-sm text-foreground">{@client.notes || "No notes"}</p>
              </div>
            </div>
          </div>

          <div class="bg-card border border-line rounded-2xl shadow-sm overflow-hidden">
            <div class="px-5 py-4 border-b border-line">
              <h2 class="text-base font-semibold text-foreground">Programme Enrollment</h2>
              <p class="text-xs text-dim mt-1">Current programme assignment</p>
            </div>
            <div class="p-5">
              <%= if @programmeUser != nil do %>
                <div class="mb-4">
                  <div class="flex items-center justify-between mb-3">
                    <div>
                      <p class="text-xs font-medium text-primary uppercase tracking-wide">
                        Currently Enrolled
                      </p>
                      <p class="text-sm font-medium text-foreground mt-1">
                        {@programmeUser.programme.name}
                      </p>
                    </div>
                    <span class="text-xs font-medium text-primary bg-primary/10 px-2 py-1 rounded-full">
                      ACTIVE
                    </span>
                  </div>
                  <.link
                    navigate={~p"/trainer/programmes/#{@programmeUser.programme_id}"}
                    class="text-xs text-primary hover:text-primary font-medium transition-colors"
                  >
                    View Programme Details →
                  </.link>
                </div>
              <% else %>
                <div class="text-center py-4">
                  <p class="text-sm font-medium text-foreground mb-1">No Programme Assigned</p>
                  <p class="text-xs text-dim">
                    This client is not currently enrolled in any programme.
                  </p>
                </div>
              <% end %>
            </div>
          </div>

          <div class="bg-card border border-line rounded-2xl shadow-sm overflow-hidden lg:col-span-2">
            <div class="px-5 py-4 border-b border-line">
              <h2 class="text-base font-semibold text-foreground">Recent Activity</h2>
              <p class="text-xs text-dim mt-1">Latest actions from this client</p>
            </div>
            <div class="p-5">
              <%= if length(@notifications) == 0 do %>
                <div class="text-center py-4">
                  <p class="text-sm text-dim">No activity yet</p>
                </div>
              <% else %>
                <div class="divide-y divide-line">
                  <%= for n <- @notifications do %>
                    <.link navigate={activity_link(n, @client.id)} class="flex items-center gap-3 py-3 hover:opacity-70 transition-opacity">

                      <div class="flex-1 min-w-0">
                        <p class="text-sm font-medium text-foreground"><%=@client.user.name%> <%= activity_label(n) %></p>
                        <p class="text-xs text-faint mt-0.5"><%= format_activity_time(n.inserted_at) %></p>
                      </div>
                      <svg class="w-4 h-4 text-dim" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="9 18 15 12 9 6"></polyline>
                      </svg>
                    </.link>
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>

          <div class="bg-card border border-line rounded-2xl shadow-sm overflow-hidden lg:col-span-2">
            <div class="px-5 py-4 border-b border-line">
              <h2 class="text-base font-semibold text-foreground">Strength Progress</h2>
              <p class="text-xs text-dim mt-1">Exercises this client has logged</p>
            </div>
            <div class="p-5">
              <%= if length(@exercise_progress_list) == 0 do %>
                <div class="text-center py-4">
                  <p class="text-sm text-dim">No exercises logged yet</p>
                </div>
              <% else %>
                <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
                  <%= for ex <- @exercise_progress_list do %>
                    <.link
                      navigate={~p"/trainer/clients/#{@client.id}/strengthProgress/#{ex.exercise_id}"}
                      class="group flex items-center justify-between rounded-xl border border-line bg-card px-4 py-3 shadow-sm hover:shadow-md hover:border-primary transition-all"
                    >
                      <div>
                        <p class="text-sm font-medium text-foreground group-hover:text-primary">
                          {ex.name}
                        </p>

                      </div>
                      <svg class="w-4 h-4 text-dim group-hover:text-primary" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="9 18 15 12 9 6"></polyline>
                      </svg>
                    </.link>
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>

          <div class="lg:col-span-2 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 lg:gap-8">
            <.link navigate={~p"/trainer/clients/#{@client.id}/workouts"} class="group bg-card border border-line rounded-2xl shadow-sm hover:shadow-md hover:border-primary transition-all overflow-hidden">
              <div class="p-5 flex items-center justify-between">
                <div class="flex items-center gap-3">
                  <div class="w-10 h-10 bg-primary/10 rounded-xl flex items-center justify-center">
                    <svg class="w-5 h-5 text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                    </svg>
                  </div>
                  <div>
                    <p class="text-sm font-semibold text-foreground group-hover:text-primary">Workout Progress</p>
                    <p class="text-xs text-dim">Monitor workouts</p>
                  </div>
                </div>
                <svg class="w-4 h-4 text-dim group-hover:text-primary" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <polyline points="9 18 15 12 9 6"></polyline>
                </svg>
              </div>
            </.link>

            <.link navigate={~p"/trainer/clients/#{@client.id}/progress-photos"} class="group bg-card border border-line rounded-2xl shadow-sm hover:shadow-md hover:border-primary transition-all overflow-hidden">
              <div class="p-5 flex items-center justify-between">
                <div class="flex items-center gap-3">
                  <div class="w-10 h-10 bg-primary/10 rounded-xl flex items-center justify-center">
                    <svg class="w-5 h-5 text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                    </svg>
                  </div>
                  <div>
                    <p class="text-sm font-semibold text-foreground group-hover:text-primary">Progress Photos</p>
                    <p class="text-xs text-dim">Visual transformation</p>
                  </div>
                </div>
                <svg class="w-4 h-4 text-dim group-hover:text-primary" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <polyline points="9 18 15 12 9 6"></polyline>
                </svg>
              </div>
            </.link>

            <.link navigate={~p"/trainer/clients/#{@client.id}/notes"} class="group bg-card border border-line rounded-2xl shadow-sm hover:shadow-md hover:border-primary transition-all overflow-hidden">
              <div class="p-5 flex items-center justify-between">
                <div class="flex items-center gap-3">
                  <div class="w-10 h-10 bg-primary/10 rounded-xl flex items-center justify-center">
                    <svg class="w-5 h-5 text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
                    </svg>
                  </div>
                  <div>
                    <p class="text-sm font-semibold text-foreground group-hover:text-primary">Notes</p>
                    <p class="text-xs text-dim">Client notes</p>
                  </div>
                </div>
                <svg class="w-4 h-4 text-dim group-hover:text-primary" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <polyline points="9 18 15 12 9 6"></polyline>
                </svg>
              </div>
            </.link>

            <.link navigate={~p"/trainer/clients/#{@client.id}/volumeTracking"} class="group bg-card border border-line rounded-2xl shadow-sm hover:shadow-md hover:border-primary transition-all overflow-hidden">
              <div class="p-5 flex items-center justify-between">
                <div class="flex items-center gap-3">
                  <div class="w-10 h-10 bg-primary/10 rounded-xl flex items-center justify-center">
                    <svg class="w-5 h-5 text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 12l3-3 3 3 4-4M8 21l4-4 4 4M3 4h18M4 4h16v12a1 1 0 01-1 1H5a1 1 0 01-1-1V4z" />
                    </svg>
                  </div>
                  <div>
                    <p class="text-sm font-semibold text-foreground group-hover:text-primary">Volume Tracking</p>
                    <p class="text-xs text-dim">Training volume</p>
                  </div>
                </div>
                <svg class="w-4 h-4 text-dim group-hover:text-primary" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <polyline points="9 18 15 12 9 6"></polyline>
                </svg>
              </div>
            </.link>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp activity_label(%{type: "workout_created"}), do: "Logged a workout"
  defp activity_label(%{type: "progress_photo_uploaded"}), do: "Uploaded a progress photo"
  defp activity_label(%{type: type}), do: type

  defp activity_link(%{type: "workout_created"}, client_id),
    do: "/trainer/clients/#{client_id}/workouts"

  defp activity_link(%{type: "progress_photo_uploaded"}, client_id),
    do: "/trainer/clients/#{client_id}/progress-photos"

  defp activity_link(_, client_id), do: "/trainer/clients/#{client_id}/workouts"

  defp format_activity_time(datetime) do
    today = DateTime.to_date(DateTime.utc_now())

    if DateTime.to_date(datetime) == today do
      Calendar.strftime(datetime, "Today, %H:%M")
    else
      Calendar.strftime(datetime, "%b %d, %H:%M")
    end
  end
end
