defmodule CrohnjobsWeb.Client.Workouts do
  alias Crohnjobs.Training
  alias Crohnjobs.Repo
  alias Crohnjobs.Clients.Client
  alias Crohnjobs.Training.Workout
  alias Crohnjobs.Notifications
  import Ecto.Query
  use CrohnjobsWeb, :live_view

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    client = Repo.get_by(Client, user_id: user.id)
    workouts = Repo.all(from w in Workout, where: w.client_id == ^client.id)
    {:ok, assign(socket, workouts: workouts)}
  end


  def handle_event("createWorkout", _params, socket) do
    user = socket.assigns.current_user
    client = Repo.get_by(Client, user_id: user.id)
    result =
      Repo.transaction(fn ->
        case Training.create_workout(%{
               client_id: client.id,
               name: "Untitled",
               date: DateTime.utc_now()
             }) do
          {:ok, workout} ->
            if client.trainer_id do
              case Notifications.create_notification(%{
                     actor_id: user.id,
                     actor_type: "client",
                     recipient_id: client.trainer_id,
                     recipient_type: "trainer",
                     type: "workout_created",
                     data: %{workout_id: workout.id, client_id: client.id}
                   }) do
                {:ok, notification} -> {workout, notification}
                {:error, changeset} -> Repo.rollback(changeset)
              end
            else
              {workout, nil}
            end

          {:error, changeset} ->
            Repo.rollback(changeset)
        end
      end)

    case result do
      {:ok, {workout, notification}} ->
        workouts = socket.assigns.workouts ++ [workout]

        if notification do
          Phoenix.PubSub.broadcast(
            Crohnjobs.PubSub,
            "notifications:trainer:#{client.trainer_id}",
            {:notification, notification}
          )
        end

        {:noreply, assign(socket, workouts: workouts)}

      {:error, _reason} ->
        {:noreply, socket |> put_flash(:error, "Unable To create workout")}
    end
  end
  def handle_event("deleteWorkout", %{"id"=>id}, socket) do
    id= String.to_integer(id)
    workout= Training.get_workout!(id)
    IO.inspect(workout)
    case Training.delete_workout(workout) do
      {:ok, _deleted}->
        workouts = Enum.reject(socket.assigns.workouts, &(&1.id == id))
        {:noreply,assign(socket,workouts: workouts)}
        _->{:noreply,socket|>put_flash(:error, "Cannot delete")}

    end


  end



  def render(assigns) do
    ~H"""
    <div class="min-h-screen">
      <!-- Header Section -->
      <div class="">
        <div class="w-full px-0 sm:px-2 lg:px-4 py-8">
          <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div>
              <h1 class="text-2xl sm:text-3xl font-bold text-gray-900">My Workouts</h1>
              <p class="text-gray-600 mt-1">Track your training progress</p>
            </div>
            <.button phx-click="createWorkout">
            Create Workout
            </.button>
          </div>
        </div>
      </div>

    <!-- Stats Section -->
      <div class="w-full px-0 sm:px-2 lg:px-4 py-8">
        <div class="mb-8">
          <div class="bg-white rounded-2xl shadow-lg p-6 border border-gray-100 hover:shadow-xl transition-shadow duration-300 max-w-sm">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-medium text-gray-600 uppercase tracking-wider">
                  Total Workouts
                </p>
                <p class="text-3xl font-bold text-gray-900 mt-2">{length(@workouts)}</p>
              </div>
              <div class="p-3 bg-emerald-100 rounded-full">
                <svg
                  class="w-8 h-8 text-emerald-600"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4"
                  >
                  </path>
                </svg>
              </div>
            </div>
          </div>
        </div>

        <%= if @workouts == [] do %>
          <div class="text-center py-16">
            <div class="mx-auto w-24 h-24 bg-gray-100 rounded-full flex items-center justify-center mb-6">
              <svg
                class="w-12 h-12 text-gray-400"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M13 10V3L4 14h7v7l9-11h-7z"
                >
                </path>
              </svg>
            </div>
            <h3 class="text-xl font-semibold text-gray-900 mb-2">No workouts yet</h3>
            <.button phx-click="createWorkout">
            Create
            </.button>

          </div>
        <% else %>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <%= for workout <- @workouts do %>
              <div class="group bg-white rounded-2xl shadow-lg hover:shadow-2xl transition-all duration-300 transform hover:-translate-y-1 border border-gray-100 overflow-hidden">
                <div class="p-6">
                  <div class="flex items-center space-x-4 mb-4">

                    <div>

                     <.link navigate={~p"/client/workouts/#{workout.id}"}>
                      <h3 class="text-xl font-bold text-gray-900 group-hover:text-emerald-600 transition-colors duration-200">
                        {workout.name || "Workout"}
                      </h3>
                      <p class="text-sm text-gray-500 flex items-center mt-1">


                        <%= if workout.date do %>
                          {Calendar.strftime(workout.date, "%B %d, %Y")}
                        <% else %>
                          No date set
                        <% end %>
                      </p>
                      </.link>
                      <.button phx-click="deleteWorkout" phx-value-id={workout.id}>
                      Delete
                      </.button>
                    </div>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
