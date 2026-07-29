defmodule ScopestrengthWeb.WorkoutDetail do
  alias Scopestrength.Trainers
  alias Scopestrength.Clients.Client
  alias Scopestrength.Exercises.ExerciseMuscleContribution
  alias Scopestrength.Repo
  alias Scopestrength.Training.Workout
  alias Scopestrength.Training.WorkoutDetails
  use ScopestrengthWeb, :live_view
  import Ecto.Query

  def mount(params, _session, socket) do
    user = socket.assigns.current_user
    trainer = Trainers.get_trainer_byUserId(user.id)

    with {:ok, client_id} <- parse_id(params["id"]),
         {:ok, workout_id} <- parse_id(params["workout_id"]),
         %Client{} = client <- Repo.get(Client, client_id) |> Repo.preload(:user),
         true <- client.trainer_id == trainer.id,
         %Workout{} = workout <- Repo.get_by(Workout, id: workout_id, client_id: client.id) do
      workouts =
        Repo.all(
          from w in WorkoutDetails,
            where: w.workout_id == ^workout_id,
            order_by: [asc: w.set]
        )
        |> Repo.preload([:exercise, :set_type])

      {grouped_workouts, muscle_group_frequencies} = build_workout_assigns(workouts)

      {:ok,
       socket
       |> assign(:client, client)
       |> assign(:workout, workout)
       |> assign(:workouts, grouped_workouts)
       |> assign(:muscle_group_frequencies, muscle_group_frequencies)}
    else
      _ ->
        {:ok,
         socket
         |> put_flash(:error, "Workout not found")
         |> redirect(to: "/trainer/clients")}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div class="mb-6">
        <div class="flex items-center justify-between">
          <div class="flex items-center space-x-4">
            <.link navigate={~p"/trainer/clients/#{@client.id}/workouts"} class="text-dim hover:text-foreground">
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"></path>
              </svg>
            </.link>
            <div>
              <h1 class="text-3xl font-bold text-foreground">Workout Details</h1>
              <p class="text-sm text-dim mt-1">
                <%= @workout.name || "Training Session" %>
                <%= if @workout.date do %>
                  · <%= Calendar.strftime(@workout.date, "%b %d, %Y") %>
                <% end %>
              </p>
            </div>
          </div>
          <div class="text-sm text-dim">
            <%= @client.user && @client.user.name %>
          </div>
        </div>
      </div>

      <div class="bg-card rounded-2xl shadow-lg border border-line">
        <%= if Enum.empty?(@workouts) do %>
          <div class="text-center py-16">
            <div class="w-20 h-20 bg-secondary rounded-full flex items-center justify-center mx-auto mb-4">
              <svg class="w-10 h-10 text-faint" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"></path>
              </svg>
            </div>
            <h3 class="text-lg font-medium text-foreground mb-2">No Exercises Yet</h3>
            <p class="text-dim">This workout has no logged exercises</p>
          </div>
        <% else %>
          <div class="p-6">
            <%= if map_size(@muscle_group_frequencies) > 0 do %>
              <div class="mb-6 bg-card rounded-xl border border-line p-4">
                <div class="flex items-center justify-between mb-3">
                  <div>
                    <h3 class="text-base font-semibold text-foreground">Session Volume</h3>
                    <p class="text-xs text-dim">Direct vs effective sets per muscle</p>
                  </div>
                </div>
                <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-3">
                  <%= for {muscle_group, volumes} <- @muscle_group_frequencies do %>
                    <div class="bg-gradient-to-br from-primary to-white border border-emerald-100 rounded-lg px-3 py-2.5">
                      <p class="text-xs font-semibold text-foreground truncate"><%= muscle_group %></p>
                      <div class="flex items-center justify-between mt-2 text-[11px] text-dim">
                        <span>Direct</span>
                        <span class="inline-flex items-center justify-center px-2 py-0.5 bg-primary text-foreground text-xs font-semibold rounded-full">
                          <%= round(volumes.direct) %>
                        </span>
                      </div>
                      <div class="flex items-center justify-between mt-1 text-[11px] text-dim">
                        <span>Effective</span>
                        <span class="inline-flex items-center justify-center px-2 py-0.5 bg-primary/10 text-primary text-xs font-semibold rounded-full">
                          <%= round(volumes.effective) %>
                        </span>
                      </div>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
            <div class="grid gap-6">
              <%= for {_exercise_id, sets} <- @workouts do %>
                <div class="border border-line rounded-xl p-5 bg-gradient-to-br from-white to-gray-50">
                  <div class="flex items-center justify-between mb-4 pb-3 border-b border-line">
                    <h3 class="text-xl font-bold text-foreground">
                      <%= List.first(sets).data.exercise.name %>
                    </h3>
                    <span class="px-3 py-1 bg-primary/10 text-primary rounded-full text-sm font-medium">
                      <%= length(sets) %> sets
                    </span>
                  </div>

                  <div class="space-y-2">
                    <%= for workout <- sets do %>
                      <div class="flex items-center justify-between p-3 bg-card rounded-lg border border-line">
                        <div class="flex items-center space-x-4">
                          <div class="flex flex-col">
                            <%= if workout.data.side != "both" do %>
                              <span class="text-sm font-bold text-foreground">Set <%= workout.data.set %></span>
                              <span class="text-xs text-dim capitalize"><%= workout.data.side %></span>
                            <% else %>
                              <span class="text-sm font-bold text-foreground">Set <%= workout.data.set %></span>
                            <% end %>
                          </div>
                          <div class="flex items-center space-x-6">
                            <div>
                              <p class="text-xs text-dim uppercase tracking-wide">Reps</p>
                              <p class="text-lg font-semibold text-foreground"><%= workout.data.reps %></p>



                            </div>
                            <div>
                              <p class="text-xs text-dim uppercase tracking-wide">Weight</p>
                              <p class="text-lg font-semibold text-foreground"><%= workout.data.weight %> kg</p>
                            </div>
                          </div>
                        </div>
                        <svg class="w-5 h-5 text-primary" fill="currentColor" viewBox="0 0 20 20">
                          <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"></path>
                        </svg>
                      </div>
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp parse_id(nil), do: :error

  defp parse_id(value) do
    case Integer.parse(value) do
      {id, ""} -> {:ok, id}
      _ -> :error
    end
  end

  defp build_workout_assigns(workouts) do
    changesets =
      Enum.map(workouts, fn workout ->
        workout |> Scopestrength.Training.change_workout_details() |> to_form()
      end)

    grouped_workouts = Enum.group_by(changesets, fn form -> form.data.exercise_id end)
    muscle_group_frequencies = build_volume_from_workouts(workouts)

    {grouped_workouts, muscle_group_frequencies}
  end

  defp build_volume_from_workouts(workouts) do
    exercise_ids =
      workouts
      |> Enum.map(& &1.exercise_id)
      |> Enum.uniq()

    if Enum.empty?(exercise_ids) do
      %{}
    else
      workouts = Repo.preload(workouts, :exercise)

      muscle_contributions =
        Repo.all(
          from c in ExerciseMuscleContribution,
            where: c.exercise_id in ^exercise_ids
        )
        |> Repo.preload(:muscle)

      contributions_by_exercise =
        muscle_contributions
        |> Enum.group_by(& &1.exercise_id)

      workouts_with_volume =
        workouts
        |> Enum.group_by(fn detail ->
          {detail.exercise_id, detail.exercise.is_unilateral, detail.set}
        end)
        |> Enum.flat_map(fn {{exercise_id, is_unilateral, _set_num}, details} ->
          if is_unilateral do
            sides = details |> Enum.map(& &1.side) |> Enum.uniq()
            set_count = if length(sides) >= 2, do: 1.0, else: 0.5

            contributions = Map.get(contributions_by_exercise, exercise_id, [])
            Enum.map(contributions, fn c ->
              {c.muscle.name, c.role, set_count * c.multiplier}
            end)
          else
            Enum.flat_map(details, fn detail ->
              contributions = Map.get(contributions_by_exercise, exercise_id, [])
              Enum.map(contributions, fn c ->
                {c.muscle.name, c.role, 1 * c.multiplier}
              end)
            end)
          end
        end)

      workouts_with_volume
      |> Enum.group_by(fn {muscle, _role, _volume} -> muscle end)
      |> Enum.map(fn {muscle, rows} ->
        direct_sets =
          rows
          |> Enum.filter(fn {_m, role, _v} -> role == "primary" end)
          |> Enum.map(fn {_m, _r, v} -> v end)
          |> Enum.sum()

        effective_sets =
          rows
          |> Enum.map(fn {_m, _r, v} -> v end)
          |> Enum.sum()

        {muscle, %{direct: direct_sets, effective: effective_sets}}
      end)
      |> Map.new()
    end
  end

end
