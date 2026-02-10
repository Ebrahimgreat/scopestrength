defmodule CrohnjobsWeb.Client.StrengthProgress do
  alias Crohnjobs.Training.Workout
  alias Crohnjobs.Training.WorkoutDetails
  alias Crohnjobs.Repo
  use CrohnjobsWeb, :live_view
  import Ecto.Query

  def mount(params, session, socket) do
    exercise_id = String.to_integer(params["exercise_id"])
    user = socket.assigns.current_user
    client = Repo.get_by(Crohnjobs.Clients.Client, %{user_id: user.id})

    # Get all workout details for this exercise across all client's workouts
    workout_details =
      Repo.all(
        from wd in WorkoutDetails,
          join: w in Workout,
          on: wd.workout_id == w.id,
          where: w.client_id == ^client.id and wd.exercise_id == ^exercise_id,
          order_by: [desc: wd.inserted_at],
          preload: :exercise
      )

    {exercise_name, max_detail} =
      if length(workout_details) > 0 do
        max_detail = Enum.max_by(workout_details, &(&1.weight))
        {hd(workout_details).exercise.name, max_detail}
      else
        {"", nil}
      end

    {:ok,
     assign(socket,
       workout_details: workout_details,
       exercise_name: exercise_name,
       max_detail: max_detail
     )}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="flex items-center justify-between">
        <h1 class="text-2xl font-bold text-gray-900">
          <%= @exercise_name %> - Strength Progress
        </h1>
        <.link navigate={~p"/client"} class="text-emerald-600 hover:text-emerald-700">
          ← Back to Dashboard
        </.link>
      </div>

      <%= if length(@workout_details) == 0 do %>
        <div class="bg-gray-100 rounded-lg p-6 text-center">
          <p class="text-gray-600">No workout data available for this exercise yet.</p>
        </div>
      <% else %>
        <!-- Max Weight Stats Card -->
        <div class="bg-gradient-to-r from-emerald-500 to-teal-500 rounded-lg shadow-lg p-6 text-white">
          <h2 class="text-lg font-semibold mb-4">Personal Record</h2>
          <div class="grid grid-cols-3 gap-4">
            <div class="bg-white bg-opacity-20 rounded-lg p-4">
              <p class="text-sm opacity-90">Max Weight</p>
              <p class="text-3xl font-bold"><%= @max_detail.weight %> kg</p>
            </div>
            <div class="bg-white bg-opacity-20 rounded-lg p-4">
              <p class="text-sm opacity-90">Reps at Max</p>
              <p class="text-3xl font-bold"><%= @max_detail.reps %></p>
            </div>
            <div class="bg-white bg-opacity-20 rounded-lg p-4">
              <p class="text-sm opacity-90">Date Achieved</p>
              <p class="text-lg font-bold">
                <%= Calendar.strftime(@max_detail.inserted_at, "%d %b %Y") %>
              </p>
            </div>
          </div>
        </div>
      <% end %>

      <%= if length(@workout_details) > 0 do %>
        <div class="bg-white shadow rounded-lg overflow-hidden">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Date
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Weight (kg)
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Sets
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Reps
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">

                </th>


              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <%= for detail <- @workout_details do %>
                <tr>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                  <%= Calendar.strftime(detail.inserted_at, "%d %b %Y") %>                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    <%= detail.weight %>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    <%= detail.set %>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    <%= detail.reps %>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    <%= if detail.side != "both" do %>
                    <%end%>
                  </td>


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
