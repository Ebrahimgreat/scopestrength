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
                 |> assign_new(:q, fn -> "" end)}

            end
        end
    end
  end

  def render(assigns) do
    ~H"""
   <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
   <div>
      <h3 class="text-sm font-medium text-gray-700 mb-3 flex items-center">
        <svg class="w-4 h-4 mr-2 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z"></path>
        </svg>
        Filter By Type
      </h3>

      </div>


   </div>

   <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
          <!-- Exercise Library Section -->
          <div class="bg-white rounded-xl shadow p-6 border">
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

            <div class="divide-y divide-gray-200 max-h-96 overflow-y-auto">
              <%= for exercise <- @exercises do %>
                <button
                  phx-click="addExercise"
                  phx-value-id={exercise.id}
                  class="bg-white text-emerlad-700 hover:bg-emerald-50 px-5 py-2.5 rounded-lg font-medium shadow-sm"
                >
                  <span class="font-medium text-gray-800"><%= exercise.name %></span>
                  <span class="text-green-600 font-bold text-lg">+</span>
                </button>
              <% end %>
            </div>
          </div>
          <!-- Workout Details -->
          <div class="bg-white rounded-xl shadow p-6 border">
          <div class="flex items-center justify-between mb-4">
          <h2 class="text-xl font-semibold text-gray-800">
          Workout Configuration
          </h2>


          </div>


          <%= for {_exercise_id, sets} <- @workouts do %>
            <div class="mb-6 p-4 bg-gray-100 rounded-lg border-2 border-gray-300">
              <h3 class="font-semibold text-lg text-gray-900 mb-3">
                <%= List.first(sets).data.exercise.name %>
              </h3>

              <%= for workout <- sets do %>
                <div class="p-4 bg-white rounded-lg border mb-3 shadow-sm">
                  <div class="flex items-center justify-between mb-2">
                    <span class="text-sm font-medium text-gray-700">Set <%= workout.data.set %></span>
                    <.button phx-click="deleteExercise" data-confirm="Are you sure you want to remove this set?" phx-value-id={workout.data.id} class="text-red-600 hover:underline text-sm">
                      Remove Set
                    </.button>
                  </div>

                  <.form phx-submit="updateExercise" for={workout} id={"workout-form-#{workout.data.id}"} class="space-y-4">
                    <.input type="hidden" field={workout[:id]}/>

                    <div class="grid grid-cols-2 gap-4">
                      <div>
                        <.input
                          label="Reps"
                          field={workout[:reps]}
                          id={"reps-#{workout.data.id}"}
                          type="text"
                          placeholder="e.g., 10, 8-12, AMRAP"
                          class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                        />
                      </div>

                      <div>
                        <.input
                          label="Weight"
                          field={workout[:weight]}
                          id={"weight-#{workout.data.id}"}
                          type="text"
                          placeholder="e.g., 135 lbs"
                          class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                        />
                      </div>
                    </div>

                    <.button class="w-full">
                      Update Set
                    </.button>
                  </.form>
                </div>
              <% end %>
            </div>
          <% end %>

          </div>
          </div>


    """
  end
end
