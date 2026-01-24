defmodule CrohnjobsWeb.Client.WorkoutShow do
alias GenLSP.Structures.ConfigurationItem
alias Crohnjobs.Training
alias Crohnjobs.Exercises.Exercise
alias CrohnjobsWeb.Exercises
  use CrohnjobsWeb, :live_view
  alias Crohnjobs.Repo
  import Ecto.Query
  alias Crohnjobs.Clients.Client
  alias Crohnjobs.Training.WorkoutDetails


  def handle_event("addExercise", params, socket) do
    exercise_id = String.to_integer(params["id"])
    existing_sets = Map.get(socket.assigns.workouts, exercise_id, [])
    next_set = length(existing_sets) + 1

    case Training.create_workout_details(%{
      workout_id: socket.assigns.workout_id,
      exercise_id: exercise_id,
      reps: 10,
      weight: 10,
      set: next_set
    }) do
      {:ok, workout_details} ->
        workout_details = Repo.preload(workout_details, :exercise)

        new_form =
          workout_details
          |> Training.change_workout_details()
          |> to_form()
        updated_workouts = Map.update(
          socket.assigns.workouts,
          exercise_id,
          [new_form],
          fn sets -> sets ++ [new_form] end
        )

        {:noreply,
         socket
         |> assign(workouts: updated_workouts)
         |> put_flash(:info, "Exercise added successfully")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to add exercise")}
    end
  end

  def handle_event("updateExercise", params, socket) do
    workout_detail_id = String.to_integer(params["workout_details"]["id"])
    workoutFound = Training.get_workout_details!(workout_detail_id)

    reps =
      case Float.parse(params["workout_details"]["reps"] || "") do
        {num, _} -> num
        :error -> nil
      end

    weight =
      case Float.parse(params["workout_details"]["weight"] || "") do
        {num, _} -> num
        :error -> nil
      end

    case Training.update_workout_details(workoutFound, %{reps: reps, weight: weight}) do
      {:ok, updated_detail} ->
        updated_detail = Repo.preload(updated_detail, :exercise)
        updated_workouts =
          socket.assigns.workouts
          |> Map.update!(updated_detail.exercise_id, fn sets ->
            Enum.map(sets, fn workout_form ->
              if workout_form.data.id == updated_detail.id do
                updated_detail
                |> Training.change_workout_details()
                |> to_form()
              else
                workout_form
              end
            end)
          end)

        {:noreply, assign(socket, workouts: updated_workouts)}

      _ ->
        {:noreply, socket |> put_flash(:error, "Error has occurred")}
    end
  end


  def handle_event("searchExercises", %{"key" => _key, "value" => value}, socket) do
    q = String.trim(value || "")

    filtered =
      socket.assigns.allExercises
      |> Enum.filter(fn ex ->
        String.contains?(String.downcase(ex.name || ""), String.downcase(q || ""))
      end)

    {:noreply, assign(socket, exercises: filtered, q: q)}
  end


  def handle_event("deleteExercise", %{"id" => id_str}, socket) do
    case Integer.parse(id_str) do
      {id, ""} ->
        workout_detail = Training.get_workout_details!(id)
        exercise_id = workout_detail.exercise_id

        case Training.delete_workout_details(workout_detail) do
          {:ok, _deleted} ->
            updated_workouts =
              socket.assigns.workouts
              |> Map.update!(exercise_id, fn sets ->
                remaining_sets = Enum.reject(sets, fn workout_form -> workout_form.data.id == id end)
                remaining_sets
                |> Enum.with_index(1)
                |> Enum.map(fn {workout_form, new_set_number} ->
                  if workout_form.data.set != new_set_number do
                    {:ok, updated} = Training.update_workout_details(workout_form.data, %{set: new_set_number})
                    updated |> Repo.preload(:exercise) |> Training.change_workout_details() |> to_form()
                  else
                    workout_form
                  end
                end)
              end)
              |> Enum.reject(fn {_exercise_id, sets} -> Enum.empty?(sets) end)
              |> Map.new()

            {:noreply,
             socket
             |> assign(workouts: updated_workouts)
             |> put_flash(:info, "Exercise removed successfully")}

          {:error, _changeset} ->
            {:noreply,
             socket
             |> put_flash(:error, "Failed to remove exercise")}
        end

      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Invalid exercise ID")}
    end
  rescue
    Ecto.NoResultsError ->
      {:noreply,
       socket
       |> put_flash(:error, "Exercise not found")}
  end

  def handle_event("toggle_edit_mode", _params, socket) do
    {:noreply, assign(socket, edit_mode: !socket.assigns.edit_mode)}
  end

  def mount(params, _session, socket) do
    user = socket.assigns.current_user



    exercises = Repo.all(Exercise)


    case Repo.get_by(Client, user_id: user.id) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Access denied")
         |> redirect(to: "/")}

      client ->
        case params["id"] do
          nil ->
            {:ok,
             socket
             |> put_flash(:error, "Invalid Workout")
             |> redirect(to: "/client")}

          workout_id ->
            case Integer.parse(workout_id) do
              :error ->
                {:ok,
                 socket
                 |> put_flash(:error, "Invalid Workout ID")
                 |> redirect(to: "/client")}

              {workout_id_int, ""} ->
                workouts =
                  Repo.all(
                    from w in WorkoutDetails,
                      where: w.workout_id == ^workout_id_int
                  )|>Repo.preload(:exercise)
                  changesets=Enum.map(workouts, fn workout-> workout|>Training.change_workout_details()|>to_form()end)
                  grouped_workouts = Enum.group_by(changesets, fn form-> form.data.exercise_id end)

                  newForm = WorkoutDetails.changeset(%WorkoutDetails{},%{})|>to_form()

                {:ok,
                 socket
                 |> assign(:client, client)
                 |> assign(:workout_id, workout_id_int)
                 |> assign(editForm: nil)
                 |> assign(newForm: newForm)
                 |> assign(:workouts, grouped_workouts)
                 |> assign(:showModal, false)
                 |> assign(exercises: exercises)
                 |> assign(allExercises: exercises)
                 |> assign(filter_by_type: "ALL")
                 |> assign(edit_mode: false)
                 |> assign_new(:q, fn -> "" end)}

            end
        end
    end
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div class="mb-6">
        <div class="flex items-center justify-between">
          <div class="flex items-center space-x-4">
            <.link navigate={~p"/client"} class="text-gray-500 hover:text-gray-700">
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"></path>
              </svg>
            </.link>
            <h1 class="text-3xl font-bold text-gray-900">Workout Details</h1>
          </div>
          <.button
            phx-click="toggle_edit_mode"
            class={"#{if @edit_mode, do: "bg-gray-600 hover:bg-gray-700", else: "bg-emerald-600 hover:bg-emerald-700"} text-white px-6 py-3 rounded-xl shadow-lg transition-all duration-200"}
          >
            <%= if @edit_mode do %>
              <svg class="w-5 h-5 inline mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
              </svg>
              Done Editing
            <% else %>
              <svg class="w-5 h-5 inline mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
              </svg>
              Edit Workout
            <% end %>
          </.button>
        </div>
      </div>

      <%= if @edit_mode do %>
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
          <div class="bg-white rounded-xl shadow-lg p-6 border border-gray-200">
            <div class="flex items-center justify-between mb-4">
              <h2 class="text-xl font-semibold text-gray-800">Exercise Library</h2>
              <span class="text-sm text-gray-500">
                <%= length(@exercises) %> available
              </span>
            </div>

            <div class="mb-4">
              <.input
                type="search"
                name="q"
                id="exercise-search"
                value={@q}
                phx-debounce="300"
                phx-keyup="searchExercises"
                placeholder="Search exercises by name..."
                class="w-full rounded-md"
              />
            </div>

            <div class="space-y-2 max-h-96 overflow-y-auto">
              <%= for exercise <- @exercises do %>
                <button
                  phx-click="addExercise"
                  phx-value-id={exercise.id}
                  class="w-full flex items-center justify-between bg-white hover:bg-emerald-50 px-4 py-3 rounded-lg border border-gray-200 hover:border-emerald-300 transition-all"
                >
                  <span class="font-medium text-gray-800"><%= exercise.name %></span>
                  <span class="text-emerald-600 font-bold text-xl">+</span>
                </button>
              <% end %>
            </div>
          </div>

          <!-- Workout Configuration (Editable) -->
          <div class="bg-white rounded-xl shadow-lg p-6 border border-gray-200">
            <h2 class="text-xl font-semibold text-gray-800 mb-4">Workout Configuration</h2>

            <%= if Enum.empty?(@workouts) do %>
              <div class="text-center py-12">
                <div class="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
                  <svg class="w-8 h-8 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
                  </svg>
                </div>
                <p class="text-gray-500">Add exercises from the library to start building your workout</p>
              </div>
            <% else %>
              <%= for {_exercise_id, sets} <- @workouts do %>
                <div class="mb-6 p-4 bg-gray-50 rounded-lg border border-gray-200">
                  <h3 class="font-semibold text-lg text-gray-900 mb-3">
                    <%= List.first(sets).data.exercise.name %>
                  </h3>

                  <%= for workout <- sets do %>
                    <div class="p-4 bg-white rounded-lg border border-gray-200 mb-3 shadow-sm">
                      <div class="flex items-center justify-between mb-2">
                        <span class="text-sm font-medium text-gray-700">Set <%= workout.data.set %></span>
                        <.button
                          phx-click="deleteExercise"
                          data-confirm="Are you sure you want to remove this set?"
                          phx-value-id={workout.data.id}
                          class="text-red-600 hover:text-red-800 text-sm"
                        >
                          Remove
                        </.button>
                      </div>

                      <.form phx-submit="updateExercise" for={workout} id={"workout-form-#{workout.data.id}"} class="space-y-3">
                        <.input type="hidden" field={workout[:id]}/>

                        <div class="grid grid-cols-2 gap-3">
                          <.input
                            label="Reps"
                            field={workout[:reps]}
                            id={"reps-#{workout.data.id}"}
                            type="text"
                            placeholder="e.g., 10"
                          />
                          <.input
                            label="Weight (kg)"
                            field={workout[:weight]}
                            id={"weight-#{workout.data.id}"}
                            type="text"
                            placeholder="e.g., 60"
                          />
                        </div>

                        <.button class="w-full bg-emerald-600 hover:bg-emerald-700">
                          Update Set
                        </.button>
                      </.form>
                    </div>
                  <% end %>
                </div>
              <% end %>
            <% end %>
          </div>
        </div>
      <% else %>
        <!-- VIEW MODE: Clean Display of Completed Workout -->
        <div class="bg-white rounded-2xl shadow-lg border border-gray-200">
          <%= if Enum.empty?(@workouts) do %>
            <div class="text-center py-16">
              <div class="w-20 h-20 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <svg class="w-10 h-10 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"></path>
                </svg>
              </div>
              <h3 class="text-lg font-medium text-gray-900 mb-2">No Exercises Yet</h3>
              <p class="text-gray-500 mb-4">Click "Edit Workout" to add exercises to this workout</p>
            </div>
          <% else %>
            <div class="p-6">
              <div class="grid gap-6">
                <%= for {_exercise_id, sets} <- @workouts do %>
                  <div class="border border-gray-200 rounded-xl p-5 bg-gradient-to-br from-white to-gray-50">
                    <!-- Exercise Header -->
                    <div class="flex items-center justify-between mb-4 pb-3 border-b border-gray-200">
                      <h3 class="text-xl font-bold text-gray-900">
                        <%= List.first(sets).data.exercise.name %>
                      </h3>
                      <span class="px-3 py-1 bg-emerald-100 text-emerald-700 rounded-full text-sm font-medium">
                        <%= length(sets) %> sets
                      </span>
                    </div>

                    <!-- Sets Display -->
                    <div class="space-y-2">
                      <%= for workout <- sets do %>
                        <div class="flex items-center justify-between p-3 bg-white rounded-lg border border-gray-200">
                          <div class="flex items-center space-x-4">
                            <div class="w-10 h-10 bg-emerald-100 rounded-full flex items-center justify-center">
                              <span class="font-bold text-emerald-700"><%= workout.data.set %></span>
                            </div>
                            <div class="flex items-center space-x-6">
                              <div>
                                <p class="text-xs text-gray-500 uppercase tracking-wide">Reps</p>
                                <p class="text-lg font-semibold text-gray-900"><%= workout.data.reps %></p>
                              </div>
                              <div>
                                <p class="text-xs text-gray-500 uppercase tracking-wide">Weight</p>
                                <p class="text-lg font-semibold text-gray-900"><%= workout.data.weight %> kg</p>
                              </div>
                            </div>
                          </div>
                          <svg class="w-5 h-5 text-emerald-500" fill="currentColor" viewBox="0 0 20 20">
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
      <% end %>
    </div>
    """
  end
end
