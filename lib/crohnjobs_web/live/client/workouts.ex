defmodule CrohnjobsWeb.Client.Workouts do
  alias Crohnjobs.Repo
  alias Crohnjobs.Clients.Client
  alias Crohnjobs.Training.Workout
  import Ecto.Query
  use CrohnjobsWeb, :live_view

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    client = Repo.get_by(Client, user_id: user.id)
    workouts = Repo.all(from w in Workout, where: w.client_id == ^client.id)
    {:ok, assign(socket, workouts: workouts)}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-zinc-50">
      <!-- Header Section -->
      <div class="bg-white shadow-lg border-b border-gray-100">
        <div class="w-full px-6 lg:px-10 py-8">
          <div class="flex items-center justify-between">
            <div class="flex items-center space-x-4">
              <div class="p-3 bg-gradient-to-r from-emerald-500 to-teal-600 rounded-xl shadow-lg">
                <svg class="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M13 10V3L4 14h7v7l9-11h-7z"
                  >
                  </path>
                </svg>
              </div>
              <div>
                <h1 class="text-3xl font-bold text-gray-900">My Workouts</h1>
                <p class="text-gray-600 mt-1">Track your training progress</p>
              </div>
            </div>
          </div>
        </div>
      </div>
      
    <!-- Stats Section -->
      <div class="w-full px-6 lg:px-10 py-8">
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
        
    <!-- Workout List -->
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
            <p class="text-gray-600 max-w-md mx-auto">
              Your trainer hasn't assigned any workouts yet. Check back soon!
            </p>
          </div>
        <% else %>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <%= for workout <- @workouts do %>
              <div class="group bg-white rounded-2xl shadow-lg hover:shadow-2xl transition-all duration-300 transform hover:-translate-y-1 border border-gray-100 overflow-hidden">
                <div class="p-6">
                  <div class="flex items-center space-x-4 mb-4">
                    <div class="w-14 h-14 bg-gradient-to-r from-emerald-400 to-teal-500 rounded-full flex items-center justify-center shadow-lg">
                      <svg
                        class="w-7 h-7 text-white"
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
                    <div>
                      <h3 class="text-xl font-bold text-gray-900 group-hover:text-emerald-600 transition-colors duration-200">
                        {workout.name || "Workout"}
                      </h3>
                      <p class="text-sm text-gray-500 flex items-center mt-1">
                        <svg
                          class="w-4 h-4 mr-1"
                          fill="none"
                          stroke="currentColor"
                          viewBox="0 0 24 24"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                          >
                          </path>
                        </svg>
                        <%= if workout.date do %>
                          {Calendar.strftime(workout.date, "%B %d, %Y")}
                        <% else %>
                          No date set
                        <% end %>
                      </p>
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
