defmodule CrohnjobsWeb.Client.StrengthProgress do
  alias Crohnjobs.Training.Workout
  alias Crohnjobs.Training.WorkoutDetails
  alias Crohnjobs.Repo
  use CrohnjobsWeb, :live_view
  import Ecto.Query

  def mount(params, _session, socket) do
    exercise_id = String.to_integer(params["exercise_id"])
    user = socket.assigns.current_user
    client = Repo.get_by(Crohnjobs.Clients.Client, %{user_id: user.id})

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
        pr = Enum.max_by(workout_details, & &1.weight)
        {hd(workout_details).exercise.name, pr}
      else
        {"", nil}
      end

    # Group by date, sorted oldest → newest
    sessions =
      workout_details
      |> Enum.group_by(& &1.workout.date)
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.map(fn {date, sets} ->
        top_set = Enum.max_by(sets, & &1.weight)
        e1rm = Float.round(top_set.weight * (1 + top_set.reps / 30.0), 1)
        %{date: date, sets: sets, top_weight: top_set.weight, e1rm: e1rm}
      end)

    grouped_workouts =
      sessions
      |> Enum.with_index()
      |> Enum.map(fn {session, idx} ->
        prev_weight = if idx > 0, do: Enum.at(sessions, idx - 1).top_weight, else: nil
        Map.put(session, :prev_top_weight, prev_weight)
      end)

    {:ok,
     assign(socket,
       exercise_name: exercise_name,
       pr: pr,
       grouped_workouts: grouped_workouts
     )}
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-4xl px-4 py-6 sm:px-6 lg:px-8">

      <!-- Header -->
      <div class="mb-6 flex items-center justify-between">
        <div>
          <h1 class="text-2xl font-semibold text-gray-900"><%= @exercise_name %></h1>
          <p class="mt-1 text-sm text-gray-500">Strength Progress</p>
        </div>
        <.link navigate={~p"/client"} class="text-sm font-medium text-gray-500 hover:text-gray-900">
          ← Back
        </.link>
      </div>

      <%= if length(@grouped_workouts) == 0 do %>
        <div class="rounded-xl border border-dashed border-gray-300 bg-gray-50 p-8 text-center">
          <p class="text-gray-500">No workout data available for this exercise yet.</p>
        </div>
      <% else %>

        <!-- PR Card -->
        <div class="mb-6 grid grid-cols-2 gap-4 sm:grid-cols-4">
          <div class="rounded-xl border border-gray-200 bg-white p-4">
            <p class="text-xs font-medium text-gray-500">Personal Record</p>
            <p class="mt-1 text-2xl font-bold text-gray-900"><%= @pr.weight %> <span class="text-sm font-normal text-gray-500">kg</span></p>
          </div>
          <div class="rounded-xl border border-gray-200 bg-white p-4">
            <p class="text-xs font-medium text-gray-500">PR Reps</p>
            <p class="mt-1 text-2xl font-bold text-gray-900"><%= @pr.reps %> <span class="text-sm font-normal text-gray-500">reps</span></p>
          </div>
          <div class="rounded-xl border border-gray-200 bg-white p-4">
            <p class="text-xs font-medium text-gray-500">Est. 1RM</p>
            <p class="mt-1 text-2xl font-bold text-emerald-600">
              <%= Float.round(@pr.weight * (1 + @pr.reps / 30.0), 1) %> <span class="text-sm font-normal text-gray-500">kg</span>
            </p>
          </div>
          <div class="rounded-xl border border-gray-200 bg-white p-4">
            <p class="text-xs font-medium text-gray-500">Sessions</p>
            <p class="mt-1 text-2xl font-bold text-gray-900"><%= length(@grouped_workouts) %></p>
          </div>
        </div>

        <!-- Session Table -->
        <div class="overflow-hidden rounded-xl border border-gray-200 bg-white">
          <div class="border-b border-gray-200 bg-gray-50 px-4 py-3 sm:px-6">
            <h2 class="text-sm font-semibold text-gray-700">Session History</h2>
          </div>
          <div class="overflow-x-auto">
            <% max_sets = @grouped_workouts |> Enum.map(fn g -> length(g.sets) end) |> Enum.max() %>
            <table class="min-w-full divide-y divide-gray-200">
              <thead>
                <tr class="bg-white">
                  <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-gray-500 sm:px-6">
                    Date
                  </th>
                  <th class="px-4 py-3 text-center text-xs font-semibold uppercase tracking-wide text-gray-500">
                    Trend
                  </th>
                  <th class="px-4 py-3 text-center text-xs font-semibold uppercase tracking-wide text-gray-500">
                    e1RM
                  </th>
                  <%= for set_num <- 1..max_sets do %>
                    <th class="px-4 py-3 text-center text-xs font-semibold uppercase tracking-wide text-gray-500">
                      Set <%= set_num %>
                    </th>
                  <% end %>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100 bg-white">
                <%= for session <- @grouped_workouts do %>
                  <% diff = if session.prev_top_weight, do: session.top_weight - session.prev_top_weight, else: nil %>
                  <tr class="hover:bg-gray-50/70">
                    <td class="whitespace-nowrap px-4 py-3 text-sm font-medium text-gray-900 sm:px-6">
                      <%= Calendar.strftime(session.date, "%d %b %Y") %>
                    </td>
                    <td class="whitespace-nowrap px-4 py-3 text-center text-sm">
                      <%= cond do %>
                        <% diff == nil -> %>
                          <span class="text-gray-300 text-xs">—</span>
                        <% diff > 0 -> %>
                          <span class="inline-flex items-center gap-1 rounded-full bg-emerald-50 px-2 py-0.5 text-xs font-medium text-emerald-700 ring-1 ring-emerald-200">
                            ▲ +<%= diff %>kg
                          </span>
                        <% diff < 0 -> %>
                          <span class="inline-flex items-center gap-1 rounded-full bg-rose-50 px-2 py-0.5 text-xs font-medium text-rose-700 ring-1 ring-rose-200">
                            ▼ <%= diff %>kg
                          </span>
                        <% true -> %>
                          <span class="inline-flex items-center rounded-full bg-gray-100 px-2 py-0.5 text-xs font-medium text-gray-500">
                            = same
                          </span>
                      <% end %>
                    </td>
                    <td class="whitespace-nowrap px-4 py-3 text-center text-sm font-semibold text-emerald-600">
                      <%= session.e1rm %>kg
                    </td>
                    <%= for set_num <- 1..max_sets do %>
                      <td class="whitespace-nowrap px-4 py-3 text-center text-sm text-gray-700">
                        <%= case Enum.find(session.sets, &(&1.set == set_num)) do %>
                          <% nil -> %>
                            <span class="text-gray-200">—</span>
                          <% s -> %>
                            <span class="font-semibold"><%= s.weight %>kg</span>
                            <span class="text-gray-400"> × </span>
                            <span><%= s.reps %></span>
                            <%= if s.side != "both" do %>
                              <div class="text-xs text-gray-400 capitalize"><%= s.side %></div>
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
