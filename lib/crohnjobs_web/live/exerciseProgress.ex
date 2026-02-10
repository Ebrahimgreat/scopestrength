defmodule CrohnjobsWeb.ExerciseProgress do
alias Crohnjobs.Repo
alias Crohnjobs.Trainers
alias Crohnjobs.Clients
alias Crohnjobs.Training.WorkoutDetails
alias Crohnjobs.Training.Workout
import Ecto.Query
  use CrohnjobsWeb, :live_view


  def mount(params, session, socket) do
    exercise_id = String.to_integer(params["exercise_id"])
    client_id = String.to_integer(params["id"])
    user = socket.assigns.current_user
    trainer = Trainers.get_trainer_byUserId(user.id)

    case Repo.get(Clients.Client, client_id) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Client Not found")
         |> push_navigate(to: "/trainer/clients")}

      client ->
        case client.trainer_id == trainer.id do
          true ->
            workout_details =
              Repo.all(
                from wd in WorkoutDetails,
                  join: w in Workout,
                  on: wd.workout_id == w.id,
                  where: w.client_id == ^client_id and wd.exercise_id == ^exercise_id,
                  order_by: [desc: wd.inserted_at],
                  preload: :exercise,
                  preload: :workout
              )

            {exercise_name, max_detail} =
              if length(workout_details) > 0 do
                max_detail = Enum.max_by(workout_details, &(&1.weight))
                {hd(workout_details).exercise.name, max_detail}
              else
                {"", nil}
              end
              grouped_workout = Enum.group_by(workout_details, &(&1.workout.date))|> Enum.map(fn{date,sets}->
                %{date: date, sets: sets}

              end)
              IO.inspect(grouped_workout)


            {:ok, assign(socket, grouped_workouts: grouped_workout, workout_details: workout_details, max_detail: max_detail)}

          false ->
            {:ok,
             socket
             |> put_flash(:error, "Client Does not exist")
             |> push_navigate(to: "/trainer/clients")}
        end
    end
  end
  def render(assigns) do
    ~H"""
    <div>
  <%= if length(@workout_details) == 0 do %>
        <div class="bg-gray-100 rounded-lg p-6 text-center">
          <p class="text-gray-600">No workout data available for this exercise yet.</p>
        </div>
      <% else %>
        <!-- Max Weight Stats Card -->
        <div class="bg-gradient-to-r from-emerald-500 to-teal-500 rounded-lg shadow-lg p-6 text-white">
          <h2 class="text-lg font-semibold mb-4">Personal Record</h2>
          <div class="grid grid-cols-2 gap-4">
            <div class="bg-white bg-opacity-20 rounded-lg p-4">
              <p class="text-sm opacity-90">Max Weight</p>
              <p class="text-3xl font-bold"><%= @max_detail.weight %> kg</p>
            </div>

            <div class="bg-white bg-opacity-20 rounded-lg p-4">
              <p class="text-sm opacity-90">Date Achieved</p>
              <p class="text-lg font-bold">
                <%= Calendar.strftime(@max_detail.workout.date, "%d %b %Y") %>
              </p>
            </div>
          </div>
        </div>
      <% end %>

      <%= if length(@workout_details) > 0 do %>
        <% max_sets = Enum.max_by(@grouped_workouts, fn g -> length(g.sets) end) |> then(& &1.sets) |> length() %>

        <div class="bg-white shadow rounded-lg overflow-hidden mt-6">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider sticky left-0 bg-gray-50">
                  Date
                </th>
                <%= for set_num <- 1..max_sets do %>
                  <th class="px-4 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Set <%= set_num %>
                  </th>
                <% end %>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <%= for detail <- @grouped_workouts do %>
                <tr class="hover:bg-gray-50">
                  <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900 sticky left-0 bg-white">
                    <%= Calendar.strftime(detail.date, "%d %b %Y") %>
                  </td>
                  <%= for set_num <- 1..max_sets do %>
                    <td class="px-4 py-4 text-center text-sm text-gray-900">
                      <%= case Enum.find(detail.sets, &(&1.set == set_num)) do %>
                        <% nil -> %>
                          <span class="text-gray-300">—</span>
                        <% set_detail -> %>
                          <div class="font-semibold">
                            <%= set_detail.weight %>×<%= set_detail.reps %>
                          </div>
                          <%= if set_detail.side != "both" do %>
                            <div class="text-xs text-gray-500 capitalize">
                              <%= set_detail.side %>
                            </div>
                          <% end %>
                      <% end %>
                    </td>
                  <% end %>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      <% end %>
    </div>
    """
  end

end
