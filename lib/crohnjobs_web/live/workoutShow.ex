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


      grouped = workout.data.workout_detail|> Enum.group_by(& &1.exercise_id)|>Enum.map(fn {exercise_id, details}->
        %{
          exercise_id: exercise_id,
          exercise: List.first(details).exercise,

          sets: details
        }

      end)
updated_workout = %{workout | data: %{workout.data | workout_detail: grouped}}
IO.inspect(updated_workout)

    fiterApplied = "All"
    {:ok, assign(socket, workout: updated_workout, allExercises: exercises, exercises: exercises, filterApplied: fiterApplied)}
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
              <%=if length(@workout.data.workout_detail)>0 do%>
             <.link navigate={~p"/clients/#{@workout.data.client_id}/workouts/#{@workout.data.id}/details"}>
            <.button> View
            </.button>

              </.link>
              <%end%>
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

            <div class="space-y-6">
  <%= for workout <- @workout.data.workout_detail do %>
    <div class="bg-gray-900 text-white rounded-2xl shadow-md p-5">
      <!-- Exercise Header -->
      <div class="flex justify-between items-center mb-3">
        <h2 class="text-xl font-semibold text-blue-400">
          <%= workout.exercise.name %>
        </h2>
        <span class="text-sm text-gray-400 italic">
          <%= workout.exercise.type %> • <%= workout.exercise.equipment %>
        </span>
      </div>

      <!-- Sets Section -->
      <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-3">
        <%= for set <- workout.sets do %>
          <div class="bg-gray-800 rounded-xl p-4 border border-gray-700 hover:border-blue-500 transition">
            <h3 class="font-medium text-blue-300">Set <%= set.set %></h3>
            <p class="text-gray-300 text-sm mt-1">
              <strong>Reps:</strong> <%= set.reps %>
            </p>
            <p class="text-gray-300 text-sm">
              <strong>Weight:</strong> <%= set.weight %> kg
            </p>
            <p class="text-gray-300 text-sm">
              <strong>RIR:</strong> <%= set.rir %>
            </p>
          </div>
        <% end %>
      </div>
    </div>
  <% end %>
</div>


      </div>
    </div>
    </div>
    """
  end
end
