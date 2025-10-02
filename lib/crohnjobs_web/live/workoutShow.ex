defmodule CrohnjobsWeb.WorkoutShow do
  alias Crohnjobs.Exercise
  alias Crohnjobs.CustomExercises.CustomExercise
  alias Crohnjobs.Trainers
  alias Crohnjobs.Fitness
  alias Crohnjobs.Repo
  use CrohnjobsWeb, :live_view
  import Ecto.Query
  alias Crohnjobs.Fitness.Workout

  @spec mount(nil | maybe_improper_list() | map(), any(), any()) :: {:ok, any()}
  def mount(params, session, socket) do
    user = socket.assigns.current_user
    trainer = Trainers.get_trainer_byUserId(user.id)
    customExercises = Repo.all(from c in CustomExercise, where: c.trainer_id == ^trainer.id)
    exercises = Exercise.list_exercises()++ customExercises
    workout_id = String.to_integer(params["workout_id"])
    workout = Repo.get(Workout, workout_id)
      |> Repo.preload(workout_detail: [:exercise])
      |> Fitness.change_workout()
      |> to_form()
    IO.inspect(workout.data.name)
    fiterApplied = "All"
    {:ok, assign(socket, workout: workout, allExercises: exercises, exercises: exercises, filterApplied: fiterApplied)}
  end

  def handle_event("updateName", params, socket) do
    case Fitness.update_workout(socket.assigns.workout.data, %{name: params["name"]}) do
      {:ok, workout} ->
        IO.inspect(workout)
        workout = %{socket.assigns.workout.data | name: params["name"]}
        myWorkout = Fitness.change_workout(workout) |> to_form()
        {:noreply, socket
          |> put_flash(:info, "Success")
          |> assign(workout: myWorkout)}
      _ -> {:noreply, socket
          |> put_flash(:info, "Something Happened")}
    end
  end

  def handle_event("updateNotes", params, socket) do
    case Fitness.update_workout(socket.assigns.workout.data, %{notes: params["notes"]}) do
      {:ok, workout} ->
        IO.inspect(workout)
        workout = %{socket.assigns.workout.data | notes: params["notes"]}
        myWorkout = Fitness.change_workout(workout) |> to_form()
        {:noreply, socket
          |> put_flash(:info, "Notes Updated")
          |> assign(workout: myWorkout)}
      _ -> {:noreply, socket
          |> put_flash(:info, "Something Happened")}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-indigo-50 via-white to-purple-50 py-8 px-4 sm:px-6 lg:px-8">
      <div class="max-w-5xl mx-auto">
        <!-- Header Section -->
        <div class="bg-white rounded-2xl shadow-lg border border-slate-200 p-8 mb-8">
          <div class="flex items-center gap-4 mb-6">
            <div class="w-16 h-16 bg-gradient-to-br from-indigo-500 to-purple-600 rounded-2xl flex items-center justify-center shadow-lg">
              <svg class="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path>
              </svg>
            </div>
            <div>
              <h1 class="text-4xl font-bold text-slate-900 capitalize"><%= @workout.data.name %></h1>
              <p class="text-slate-600 mt-1">Workout Details & Exercise Log</p>
            </div>
          </div>

          <!-- Edit Forms Grid -->
          <div class="grid md:grid-cols-2 gap-6">
            <!-- Update Name Form -->
            <div class="bg-gradient-to-br from-slate-50 to-slate-100 rounded-xl p-6 border border-slate-200">
              <div class="flex items-center gap-2 mb-4">
                <svg class="w-5 h-5 text-indigo-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
                </svg>
                <h3 class="text-lg font-semibold text-slate-900">Update Name</h3>
              </div>
              <.form phx-submit="updateName" class="space-y-4">
                <.input
                  label="Workout Name"
                  name="name"
                  field={@workout[:name]}
                  class="w-full px-4 py-2 rounded-lg border-slate-300 focus:border-indigo-500 focus:ring-indigo-500"
                />
                <.button class="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-semibold py-3 rounded-lg shadow-md hover:shadow-lg transition-all duration-200 flex items-center justify-center gap-2">
                  <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
                  </svg>
                  Update Name
                </.button>
              </.form>
            </div>

            <!-- Update Notes Form -->
            <div class="bg-gradient-to-br from-slate-50 to-slate-100 rounded-xl p-6 border border-slate-200">
              <div class="flex items-center gap-2 mb-4">
                <svg class="w-5 h-5 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
                </svg>
                <h3 class="text-lg font-semibold text-slate-900">Update Notes</h3>
              </div>
              <.form phx-submit="updateNotes" class="space-y-4">
                <.input
                  label="Workout Notes"
                  name="notes"
                  field={@workout[:notes]}
                  class="w-full px-4 py-2 rounded-lg border-slate-300 focus:border-purple-500 focus:ring-purple-500"
                />
                <.button class="w-full bg-purple-600 hover:bg-purple-700 text-white font-semibold py-3 rounded-lg shadow-md hover:shadow-lg transition-all duration-200 flex items-center justify-center gap-2">
                  <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
                  </svg>
                  Update Notes
                </.button>
              </.form>
            </div>
          </div>
        </div>

        <!-- Exercise Details Section -->
        <div class="bg-white rounded-2xl shadow-lg border border-slate-200 p-8">
          <div class="flex items-center gap-3 mb-6">
            <div class="w-10 h-10 bg-gradient-to-br from-emerald-500 to-teal-600 rounded-lg flex items-center justify-center">
              <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path>
              </svg>
            </div>
            <h2 class="text-2xl font-bold text-slate-900">Exercise Log</h2>
          </div>

          <%= if length(@workout.data.workout_detail) == 0 do %>
            <!-- Empty State -->
            <div class="text-center py-12">
              <div class="inline-flex items-center justify-center w-16 h-16 bg-slate-100 rounded-full mb-4">
                <svg class="w-8 h-8 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4"></path>
                </svg>
              </div>
              <h3 class="text-lg font-semibold text-slate-900 mb-2">No exercises logged</h3>
              <p class="text-slate-600">Start adding exercises to track your workout progress</p>
            </div>
          <% else %>
            <!-- Exercise Cards Grid -->
            <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              <%= for workoutDetail <- @workout.data.workout_detail do %>
                <div class="bg-gradient-to-br from-slate-50 to-white rounded-xl p-5 border-2 border-slate-200 hover:border-indigo-300 transition-all duration-200 hover:shadow-md">
                  <!-- Exercise Name -->
                  <div class="flex items-center gap-2 mb-4 pb-3 border-b border-slate-200">
                    <div class="w-8 h-8 bg-gradient-to-br from-indigo-500 to-purple-600 rounded-lg flex items-center justify-center flex-shrink-0">
                      <svg class="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                      </svg>
                    </div>
                    <h3 class="font-bold text-slate-900 capitalize text-lg"><%= workoutDetail.exercise.name %></h3>
                  </div>

                  <!-- Exercise Stats -->
                  <div class="space-y-3">
                    <div class="flex items-center justify-between">
                      <span class="flex items-center gap-2 text-sm text-slate-600">
                        <svg class="w-4 h-4 text-indigo-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 20l4-16m2 16l4-16M6 9h14M4 15h14"></path>
                        </svg>
                        Sets
                      </span>
                      <span class="font-bold text-slate-900 text-lg"><%= workoutDetail.set %></span>
                    </div>

                    <div class="flex items-center justify-between">
                      <span class="flex items-center gap-2 text-sm text-slate-600">
                        <svg class="w-4 h-4 text-purple-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"></path>
                        </svg>
                        Reps
                      </span>
                      <span class="font-bold text-slate-900 text-lg"><%= workoutDetail.reps %></span>
                    </div>

                    <div class="flex items-center justify-between">
                      <span class="flex items-center gap-2 text-sm text-slate-600">
                        <svg class="w-4 h-4 text-emerald-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 6l3 1m0 0l-3 9a5.002 5.002 0 006.001 0M6 7l3 9M6 7l6-2m6 2l3-1m-3 1l-3 9a5.002 5.002 0 006.001 0M18 7l3 9m-3-9l-6-2m0-2v2m0 16V5m0 16H9m3 0h3"></path>
                        </svg>
                        Weight
                      </span>
                      <span class="font-bold text-slate-900 text-lg"><%= workoutDetail.weight %> <span class="text-sm text-slate-500">lbs</span></span>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>

            <!-- Summary Stats -->
            <div class="mt-6 pt-6 border-t border-slate-200">
              <div class="flex items-center justify-center gap-2 text-sm text-slate-600">
                <svg class="w-5 h-5 text-emerald-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path>
                </svg>
                <span class="font-semibold text-slate-900"><%= length(@workout.data.workout_detail) %></span>
                <%= if length(@workout.data.workout_detail) == 1, do: "exercise", else: "exercises" %> logged
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
