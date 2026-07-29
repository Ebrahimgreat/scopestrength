defmodule ScopestrengthWeb.Client.StrengthProgress do
  alias Scopestrength.Training.Workout
  alias Scopestrength.Training.WorkoutDetails
  alias Scopestrength.Repo
  use ScopestrengthWeb, :live_view
  import Ecto.Query

  defp top_set(sets) do
    Enum.max_by(sets, fn s -> {s.weight || 0, s.reps || 0} end)
  end

  def mount(params, _session, socket) do
    exercise_id = String.to_integer(params["exercise_id"])
    user = socket.assigns.current_user
    client = Repo.get_by(Scopestrength.Clients.Client, %{user_id: user.id})

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

    # Group by date, sorted oldest → newest
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
       overall_avg_reps: overall_avg_reps
     )}
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-4xl px-4 py-6 sm:px-6 lg:px-8">

      <!-- Header -->
      <div class="mb-6 flex items-center justify-between">
        <div>
          <h1 class="text-2xl font-semibold text-foreground"><%= @exercise_name %></h1>
          <p class="mt-1 text-sm text-dim">Strength Progress</p>
        </div>
        <.link navigate={~p"/client"} class="text-sm font-medium text-dim hover:text-foreground">
          ← Back
        </.link>
      </div>

      <%= if length(@grouped_workouts) == 0 do %>
        <div class="rounded-xl border border-dashed border-line bg-card p-8 text-center">
          <p class="text-dim">No workout data available for this exercise yet.</p>
        </div>
      <% else %>

        <!-- PR Card -->
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

        <!-- Session Table -->
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
                          <span class="inline-flex items-center gap-1 rounded-full bg-primary/10 px-2 py-0.5 text-xs font-medium text-primary ring-1 ring-emerald-200">
                            ▲ +<%= Float.round(session.top_weight - session.prev.top_weight, 1) %>kg
                          </span>
                        <% session.top_weight < session.prev.top_weight -> %>
                          <span class="inline-flex items-center gap-1 rounded-full bg-danger/10 px-2 py-0.5 text-xs font-medium text-danger ring-1 ring-rose-200">
                            ▼ <%= Float.round(session.top_weight - session.prev.top_weight, 1) %>kg
                          </span>
                        <% session.top_reps > session.prev.top_reps -> %>
                          <span class="inline-flex items-center gap-1 rounded-full bg-primary/10 px-2 py-0.5 text-xs font-medium text-primary ring-1 ring-emerald-200">
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
