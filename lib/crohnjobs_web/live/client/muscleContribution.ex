defmodule CrohnjobsWeb.Client.MuscleContribution do
  alias Crohnjobs.Repo
  alias Crohnjobs.Clients
  alias Crohnjobs.Training.WorkoutDetails
  alias Crohnjobs.Training.Workout
  alias Crohnjobs.Exercises.Exercise
  alias Crohnjobs.Exercises.Muscles
  alias Crohnjobs.Exercises.ExerciseMuscleContribution
  import Ecto.Query
  use CrohnjobsWeb, :live_view

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
                by_date =
                  ex_entries
                  |> Enum.group_by(&DateTime.to_date(&1.date))
                  |> Enum.sort_by(&elem(&1, 0), {:desc, Date})
                {ex_name, by_date}
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
    by_date = exercises |> Map.get(role, %{}) |> Map.get(exercise_name, [])
    ceil(length(by_date) / @page_size)
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-4xl px-4 py-6 sm:px-6 lg:px-8">
      <div class="mb-6">
        <h1 class="text-2xl font-semibold text-gray-900"><%= @muscle.name %> Volume</h1>
        <p class="mt-1 text-sm text-gray-500">All exercises performed for this muscle group</p>
      </div>

      <%= if map_size(@exercises) == 0 do %>
        <div class="rounded-xl border border-dashed border-gray-300 bg-gray-50 p-8 text-center">
          <p class="text-gray-500">No exercises recorded for <%= @muscle.name %> yet.</p>
        </div>
      <% else %>
        <div class="space-y-8">
          <%= for {role, by_exercise} <- [{"primary", Map.get(@exercises, "primary", %{})}, {"secondary", Map.get(@exercises, "secondary", %{})}] do %>
            <%= if map_size(by_exercise) > 0 do %>
              <section>
                <h2 class={[
                  "mb-3 text-xs font-semibold uppercase tracking-wide",
                  if(role == "primary", do: "text-emerald-700", else: "text-blue-700")
                ]}>
                  <%= if role == "primary", do: "Direct (Primary)", else: "Indirect (Secondary)" %>
                </h2>

                <div class="space-y-4">
                  <%= for {exercise_name, by_date} <- by_exercise |> Enum.sort_by(&elem(&1, 0)) do %>
                    <% key = "#{role}||#{exercise_name}" %>
                    <% current_page = Map.get(@pages, key, 0) %>
                    <% total_pages = ceil(length(by_date) / 5) %>
                    <% page_sessions = Enum.slice(by_date, current_page * 5, 5) %>

                    <div class="overflow-hidden rounded-xl border border-gray-200 bg-white">
                      <div class="flex items-center justify-between border-b border-gray-100 bg-gray-50 px-4 py-2.5">
                        <h3 class="text-sm font-semibold text-gray-900"><%= exercise_name %></h3>
                        <span class="text-xs text-gray-400"><%= length(by_date) %> sessions</span>
                      </div>

                      <div class="divide-y divide-gray-100">
                        <%= for {date, sets} <- page_sessions do %>
                          <div class="px-4 py-3">
                            <p class="mb-2 text-xs font-medium text-gray-500">
                              <%= Calendar.strftime(date, "%b %d, %Y") %>
                            </p>
                            <div class="flex flex-wrap gap-2">
                              <%= for s <- sets do %>
                                <span class="inline-flex items-center rounded-full bg-gray-100 px-2.5 py-1 text-xs font-medium text-gray-700">
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
                        <div class="flex items-center justify-between border-t border-gray-100 px-4 py-2.5">
                          <button
                            phx-click="prev_page"
                            phx-value-key={key}
                            disabled={current_page == 0}
                            class="text-xs font-medium text-gray-500 hover:text-gray-900 disabled:opacity-30 disabled:cursor-not-allowed"
                          >
                            ← Previous
                          </button>
                          <span class="text-xs text-gray-400">
                            <%= current_page + 1 %> / <%= total_pages %>
                          </span>
                          <button
                            phx-click="next_page"
                            phx-value-key={key}
                            disabled={current_page + 1 >= total_pages}
                            class="text-xs font-medium text-gray-500 hover:text-gray-900 disabled:opacity-30 disabled:cursor-not-allowed"
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
