defmodule CrohnjobsWeb.Workouts do
  alias Crohnjobs.Fitness
  alias Crohnjobs.Repo
  use CrohnjobsWeb, :live_view
  alias Crohnjobs.Clients.Client
  alias Crohnjobs.Fitness.Workout
  import Ecto.Query

  def handle_event("addWorkout", _params, socket) do
    client_id = socket.assigns.client.id
    new_workout = %{
      name: "workout",
      date: ~D[2025-02-21],
      notes: "null",
      client_id: client_id
    }
    case Fitness.create_workout(new_workout) do
      {:ok, workout} ->
        workout = Repo.get!(Workout, workout.id)
        IO.inspect(workout)
        {:noreply, socket
          |> put_flash(:info, "New Workout Added")
          |> assign(:workouts, [workout | socket.assigns.workouts])}
      _ -> {:noreply, socket
          |> put_flash(:error, "An error has occured")}
    end
  end

  def handle_event("removeWorkout", %{"id"=>id}, socket) do
    id = String.to_integer(id)
    IO.inspect(id)
    workout = Fitness.get_workout!(id)
    IO.inspect(workout)
    case Fitness.delete_workout(workout) do
      {:ok, _workout}->
        workouts = Enum.reject(socket.assigns.workouts, &(&1.id == id))
        IO.inspect(workouts)
        {:noreply, socket
          |> put_flash(:info, "Workout Deleted Succesfully")
          |> assign(workouts: workouts)}
      _ -> {:noreply, socket
          |> put_flash(:error, "Something Happneed")}
    end
  end

  def mount(params, session, socket) do
    client = Repo.get!(Client, params["id"])
    workouts = Repo.all(from w in Workout, where: w.client_id == ^client.id)
    IO.inspect(workouts)
    {:ok, assign(socket, workouts: workouts, client: client)}
  end

  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100 py-8 px-4 sm:px-6 lg:px-8">
      <div class="max-w-4xl mx-auto">
        <!-- Header Section -->
        <div class="bg-white rounded-2xl shadow-sm border border-slate-200 p-6 mb-6">
          <div class="flex items-center justify-between">
            <div>
              <h1 class="text-3xl font-bold text-slate-900"> {@client.name} </h1>
              <p class="text-slate-600 mt-1">Tracking the workouts of a given client</p>
            </div>
            <.button
              phx-click="addWorkout"
              class="bg-blue-600 hover:bg-blue-700 text-white font-semibold px-6 py-3 rounded-xl shadow-md hover:shadow-lg transition-all duration-200 flex items-center gap-2"
            >
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>
              </svg>
              Create Workout
            </.button>
          </div>
        </div>

        <!-- Empty State -->
        <%= if length(@workouts) == 0 do %>
          <div class="bg-white rounded-2xl shadow-sm border border-slate-200 p-12 text-center">
            <div class="inline-flex items-center justify-center w-16 h-16 bg-slate-100 rounded-full mb-4">
              <svg class="w-8 h-8 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"></path>
              </svg>
            </div>
            <h3 class="text-xl font-semibold text-slate-900 mb-2">No workouts yet</h3>
            <p class="text-slate-600 max-w-sm mx-auto">Get started by creating The  workout session. Track progress of client!</p>
          </div>
        <% else %>
          <!-- Workouts Grid -->
          <div class="grid gap-4 sm:grid-cols-1 md:grid-cols-2">
            <%= for workout <- @workouts do %>
              <div class="bg-white rounded-xl shadow-sm border border-slate-200 p-6 hover:shadow-md transition-shadow duration-200">
                <!-- Workout Header -->
                <div class="flex items-start justify-between mb-4">
                  <div class="flex items-center gap-3">
                    <div class="w-12 h-12 bg-gradient-to-br from-blue-500 to-blue-600 rounded-lg flex items-center justify-center shadow-sm">
                      <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path>
                      </svg>
                    </div>
                    <div>
                      <h3 class="text-lg font-semibold text-slate-900 capitalize"><%= workout.name %></h3>
                      <.link  navigate={~p"/clients/#{@client.id}/workouts/#{workout.id}"}>
                      View
                      </.link>
                      <div class="flex items-center gap-1 text-sm text-slate-500 mt-0.5">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
                        </svg>
                        <%= Calendar.strftime(workout.date, "%B %d, %Y") %>
                      </div>
                    </div>
                  </div>
                  <.button
                    phx-click="removeWorkout"
                    phx-value-id={workout.id}
                    class="text-red-600 hover:text-red-700 hover:bg-red-50 p-2 rounded-lg transition-colors duration-200"
                  >
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                    </svg>
                  </.button>
                </div>

                <!-- Workout Notes -->
                <%= if workout.notes && workout.notes != "null" do %>
                  <div class="bg-slate-50 rounded-lg p-3 border border-slate-100">
                    <div class="flex items-start gap-2">
                      <svg class="w-4 h-4 text-slate-400 mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
                      </svg>
                      <p class="text-sm text-slate-700"><%= workout.notes %></p>
                    </div>
                  </div>
                <% else %>
                  <p class="text-sm text-slate-400 italic">No notes added</p>
                <% end %>
              </div>
            <% end %>
          </div>

          <!-- Workouts Count -->
          <div class="mt-6 text-center">
            <p class="text-sm text-slate-600">
              <span class="font-semibold text-slate-900"><%= length(@workouts) %></span>
              <%= if length(@workouts) == 1, do: "workout", else: "workouts" %> total
            </p>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
