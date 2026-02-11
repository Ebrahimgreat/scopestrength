defmodule CrohnjobsWeb.Client.WorkoutShow do
alias Crohnjobs.Trainers
alias Crohnjobs.Programmes.ProgrammeUser
alias GenLSP.Structures.ConfigurationItem
alias Crohnjobs.Training
alias Crohnjobs.Training.Workout
alias Crohnjobs.Exercises.Exercise
alias Crohnjobs.Exercises.ExerciseMuscleContribution
alias Crohnjobs.Exercises
alias CrohnjobsWeb.Exercises, as: ExercisesLiveView
  use CrohnjobsWeb, :live_view
  alias Crohnjobs.Repo
  import Ecto.Query
  alias Crohnjobs.Clients.Client
  alias Crohnjobs.Training.WorkoutDetails


  def handle_event("filterExercise", %{"name" => name}, socket) do
    filter_applied = name

    filtered =
      apply_exercise_filters(socket.assigns.allExercises, filter_applied, socket.assigns.q)

    {:noreply, assign(socket, exercises: filtered, filter_by_type: filter_applied)}
  end

  def handle_event("resetFilters", _params, socket) do
    exercises = apply_exercise_filters(socket.assigns.allExercises, "ALL", "")
    {:noreply, assign(socket, exercises: exercises, filter_by_type: "ALL", q: "")}
  end

  def handle_event("addExercise", params, socket) do
    exercise_id = String.to_integer(params["id"])
    IO.inspect(exercise_id)
    existing_sets = Map.get(socket.assigns.workouts, exercise_id, [])
    next_set = length(existing_sets) + 1

    # Get side parameter if provided (for unilateral exercises)
    side = Map.get(params, "side", "both")

    case Training.create_workout_details(%{
      workout_id: socket.assigns.workout_id,
      exercise_id: exercise_id,
      reps: 10,
      weight: 10,
      set: next_set,
      side: side
    }) do
      {:ok, workout_details} ->
        workout_details = Repo.preload(workout_details, [:exercise, :set_type])

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

    set_type_id =
      case params["workout_details"]["set_type_id"] do
        nil -> nil
        "" -> nil
        id -> String.to_integer(id)
      end

    notes = params["workout_details"]["notes"]

    # Store pending changes instead of saving immediately
    pending_changes = Map.put(
      socket.assigns.pending_changes,
      workout_detail_id,
      %{reps: reps, weight: weight, set_type_id: set_type_id, notes: notes}
    )

    # Update the form display
    updated_workouts =
      socket.assigns.workouts
      |> Enum.map(fn {exercise_id, sets} ->
        updated_sets = Enum.map(sets, fn workout_form ->
          if workout_form.data.id == workout_detail_id do
            updated_data = %{workout_form.data | reps: reps, weight: weight, set_type_id: set_type_id, notes: notes}
            updated_data
            |> Training.change_workout_details()
            |> to_form()
          else
            workout_form
          end
        end)
        {exercise_id, updated_sets}
      end)
      |> Map.new()

    {:noreply, assign(socket, workouts: updated_workouts, pending_changes: pending_changes, has_unsaved_changes: true)}
  end

  def handle_event("save_all_changes", _params, socket) do
    case save_pending_changes(socket.assigns.pending_changes) do
      :ok ->
        {:noreply,
         socket
         |> assign(pending_changes: %{}, has_unsaved_changes: false)
         |> put_flash(:info, "All changes saved successfully")}

      {:error, _reason} ->
        {:noreply, socket |> put_flash(:error, "Failed to save some changes")}
    end
  end

  def handle_event("auto_save_on_leave", _params, socket) do
    if socket.assigns.has_unsaved_changes do
      save_pending_changes(socket.assigns.pending_changes)
    end
    {:noreply, socket}
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
                    updated |> Repo.preload([:exercise, :set_type]) |> Training.change_workout_details() |> to_form()
                  else
                    workout_form
                  end
                end)
              end)
              |> Enum.reject(fn {_exercise_id, sets} -> Enum.empty?(sets) end)
              |> Map.new()

            # Remove deleted workout_detail from pending changes
            updated_pending_changes = Map.delete(socket.assigns.pending_changes, id)

            {:noreply,
             socket
             |> assign(workouts: updated_workouts)
             |> assign(pending_changes: updated_pending_changes)
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
    # If exiting edit mode and there are unsaved changes, save them
    socket = if socket.assigns.edit_mode and socket.assigns.has_unsaved_changes do
      case save_pending_changes(socket.assigns.pending_changes) do
        :ok ->
          socket
          |> assign(pending_changes: %{}, has_unsaved_changes: false)
          |> put_flash(:info, "Changes saved successfully")
        {:error, _} ->
          socket
          |> put_flash(:error, "Failed to save some changes")
      end
    else
      socket
    end

    {:noreply, assign(socket, edit_mode: !socket.assigns.edit_mode)}
  end

  def handle_event("update_workout", %{"workout" => params}, socket) do
    attrs = normalize_workout_attrs(params)

    case Training.update_workout(socket.assigns.workout, attrs) do
      {:ok, updated} ->
        {:noreply,
         socket
         |> assign(:workout, updated)
         |> assign(:workout_form, Training.change_workout(updated) |> to_form())
         |> put_flash(:info, "Workout updated")}

      {:error, changeset} ->
        {:noreply, assign(socket, :workout_form, to_form(changeset))}
    end
  end

  def handle_event("load_from_programme", %{"template-id" => template_id}, socket) do
    workout_id = socket.assigns.workout_id

    template =
      socket.assigns.programme
      |> case do
        nil -> nil
        programme_user -> programme_user.programme.programmeTemplates
      end
      |> case do
        nil -> nil
        templates -> Enum.find(templates, &("#{&1.id}" == template_id))
      end

    if template do
      result =
        Repo.transaction(fn ->
          Repo.delete_all(from w in WorkoutDetails, where: w.workout_id == ^workout_id)

          template.programmeDetails
          |> Enum.uniq_by(& &1.exercise_id)
          |> Enum.each(fn detail ->
            # Check if exercise is unilateral
            if detail.exercise.is_unilateral do
              # Create left side set
              left_attrs = %{
                workout_id: workout_id,
                exercise_id: detail.exercise_id,
                set: 1,
                side: "left",
                reps: 10,
                weight: nil
              }

              # Create right side set
              right_attrs = %{
                workout_id: workout_id,
                exercise_id: detail.exercise_id,
                set: 1,
                side: "right",
                reps: 10,
                weight: nil
              }

              case Training.create_workout_details(left_attrs) do
                {:ok, _} ->
                  case Training.create_workout_details(right_attrs) do
                    {:ok, _} -> :ok
                    {:error, changeset} -> Repo.rollback(changeset)
                  end

                {:error, changeset} ->
                  Repo.rollback(changeset)
              end
            else
              # Create normal bilateral set
              attrs = %{
                workout_id: workout_id,
                exercise_id: detail.exercise_id,
                set: 1,
                reps: 10,
                weight: nil
              }

              case Training.create_workout_details(attrs) do
                {:ok, _} -> :ok
                {:error, changeset} -> Repo.rollback(changeset)
              end
            end
          end)
        end)

      case result do
        {:ok, _} ->
          workouts =
            Repo.all(
              from w in WorkoutDetails,
                where: w.workout_id == ^workout_id,
                order_by: [asc: w.set]
            )
            |> Repo.preload([:exercise, :set_type])

          {grouped_workouts, muscle_group_frequencies} = build_workout_assigns(workouts)

          {:noreply,
           socket
           |> assign(:workouts, grouped_workouts)
           |> assign(:muscle_group_frequencies, muscle_group_frequencies)
           |> put_flash(:info, "Workout loaded from programme")}

        {:error, _} ->
          {:noreply, socket |> put_flash(:error, "Failed to load programme")}
      end
    else
      {:noreply, socket |> put_flash(:error, "Template not found")}
    end
  end

  def mount(params, _session, socket) do
    user = socket.assigns.current_user
    client = Repo.get_by(Crohnjobs.Clients.Client, %{user_id: user.id})

    # Get trainer if available
    trainer = case client.trainer_id do
      nil -> nil
      trainer_id -> Repo.get_by(Crohnjobs.Trainers.Trainer, %{id: trainer_id})
    end

    exercises = case trainer do
      nil ->
        Repo.all(
          from e in Exercise,
            where: e.is_custom == false or e.user_id == ^user.id,
            order_by: [asc: e.name],
            preload: [:muscle, :equipment]
        )
      trainer ->
        Repo.all(
          from e in Exercise,
            where: e.is_custom == false or e.user_id == ^user.id or e.user_id == ^trainer.user_id,
            order_by: [asc: e.name],
            preload: [:muscle, :equipment]
        )
    end

    # Get muscles list for filtering
    muscles = Exercises.list_mucles()
    set_types= Repo.all(Crohnjobs.Training.SetType)

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
                workout = Repo.get_by(Workout, id: workout_id_int, client_id: client.id)

                if is_nil(workout) do
                  {:ok,
                   socket
                   |> put_flash(:error, "Invalid Workout")
                   |> redirect(to: "/client")}
                else
                workout_form = Training.change_workout(workout) |> to_form()
                workouts =
                  Repo.all(
                    from w in WorkoutDetails,
                      where: w.workout_id == ^workout_id_int,
                      order_by: [asc: w.set]
                  )|>Repo.preload([:exercise, :set_type])

                  IO.inspect(workouts)

                {grouped_workouts, muscle_group_frequencies} = build_workout_assigns(workouts)

                  programme =
                    Repo.get_by(ProgrammeUser, %{
                      client_id: client.id,
                      is_active: true
                    })|>Repo.preload(programme: [programmeTemplates: [programmeDetails: :exercise]])

                  newForm = WorkoutDetails.changeset(%WorkoutDetails{},%{})|>to_form()

                {:ok,
                 socket
                 |> assign(:client, client)
                 |>assign(:programme, programme)
                 |> assign(:workout_id, workout_id_int)
                 |> assign(:workout, workout)
                 |> assign(:workout_form, workout_form)
                 |> assign(editForm: nil)
                 |> assign(newForm: newForm)
                 |> assign(:workouts, grouped_workouts)
                 |> assign(:showModal, false)
                 |> assign(exercises: exercises)
                 |> assign(allExercises: exercises)
                 |> assign(muscles: muscles)
                 |> assign(setTypes: set_types)
                 |> assign(filter_by_type: "ALL")
                 |> assign(muscle_group_frequencies: muscle_group_frequencies)
                 |> assign(edit_mode: false)
                 |> assign(pending_changes: %{})
                 |> assign(has_unsaved_changes: false)
                 |> assign_new(:q, fn -> "" end)}
                end

            end
        end
    end
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8" phx-hook="AutoSave" id="workout-container">
      <div class="mb-6">
        <div class="flex items-center justify-between">
          <div class="flex items-center space-x-4">
            <.link navigate={~p"/client"} phx-click="auto_save_on_leave" class="text-gray-500 hover:text-gray-700">
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"></path>
              </svg>
            </.link>
            <h1 class="text-3xl font-bold text-gray-900">Workout Details</h1>
            <%= if @has_unsaved_changes do %>
              <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-amber-100 text-amber-800">
                <svg class="w-3 h-3 mr-1" fill="currentColor" viewBox="0 0 20 20">
                  <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd"/>
                </svg>
                Unsaved changes
              </span>
            <% end %>
          </div>
          <div class="flex items-center gap-3">
            <%= if @has_unsaved_changes and @edit_mode do %>
              <.button
                phx-click="save_all_changes"
                class="bg-emerald-600 hover:bg-emerald-700 text-white px-6 py-3 rounded-xl shadow-lg transition-all duration-200"
              >
                <svg class="w-5 h-5 inline mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
                </svg>
                Save All Changes
              </.button>
            <% end %>
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
    </div>

      <%= if @edit_mode do %>
        <div class="mb-8 bg-white rounded-xl shadow-lg p-6 border border-gray-200">
          <h2 class="text-lg font-semibold text-gray-900">Update Workout</h2>
          <.form for={@workout_form} phx-submit="update_workout" class="mt-4 space-y-4 max-w-xl">
            <div>
              <label class="block text-sm font-medium text-slate-700">Name</label>
              <.input
                field={@workout_form[:name]}
                type="text"
                class="w-full px-3 py-2 border border-slate-300 rounded-md text-sm"
                placeholder="Workout name"
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-slate-700">Date</label>
              <.input
                field={@workout_form[:date]}
                type="datetime-local"
                class="w-full px-3 py-2 border border-slate-300 rounded-md text-sm"
              />
              <p class="text-xs text-slate-500 mt-1">Stored in UTC.</p>
            </div>
            <.button class="px-4 py-2 text-sm">
              Save
            </.button>
          </.form>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
          <div class="bg-white rounded-xl shadow-lg p-6 border border-gray-200">
            <%= if @programme && @programme.programme && length(@programme.programme.programmeTemplates) > 0 do %>
              <div class="mb-6 border border-emerald-100 bg-emerald-50/40 rounded-lg p-4">
                <div class="flex items-center justify-between mb-3">
                  <div>
                    <h2 class="text-sm font-semibold text-emerald-900">Load from programme</h2>
                    <p class="text-xs text-emerald-700">Replaces current workout with 1 set per exercise.</p>
                  </div>
                </div>
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-2">
                  <%= for template <- @programme.programme.programmeTemplates do %>
                    <button
                      type="button"
                      phx-click="load_from_programme"
                      phx-value-template-id={template.id}
                      data-confirm="This will replace your current workout. Continue?"
                      class="flex items-center justify-between rounded-lg border border-emerald-200 bg-white px-3 py-2 text-xs font-semibold text-emerald-800 hover:bg-emerald-50"
                    >
                      <span class="truncate"><%= template.name %></span>
                      <span class="text-[10px] text-emerald-600">Load</span>
                    </button>
                  <% end %>
                </div>
              </div>
            <% end %>

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

            <div class="mb-4 flex flex-wrap gap-2">
              <button
                type="button"
                phx-click="resetFilters"
                class="px-2 py-1 text-xs font-medium rounded-lg border border-slate-300 bg-white text-slate-700 hover:bg-slate-50 transition"
              >
                Reset
              </button>
              <button
                type="button"
                phx-click="filterExercise"
                phx-value-name="ALL"
                class={[
                  "px-2 py-1 text-xs font-medium rounded-lg transition",
                  if(@filter_by_type == "ALL",
                    do: "bg-emerald-600 text-white",
                    else: "bg-slate-100 text-slate-700 hover:bg-slate-200"
                  )
                ]}
              >
                All
              </button>
              <%= for muscle <- @muscles do %>
                <button
                  type="button"
                  phx-click="filterExercise"
                  phx-value-name={muscle.name}
                  class={[
                    "px-2 py-1 text-xs font-medium rounded-full border transition",
                    if(@filter_by_type == muscle.name,
                      do: "bg-emerald-50 text-emerald-700 border-emerald-200",
                      else: "bg-white text-slate-700 border-slate-200 hover:bg-slate-50"
                    )
                  ]}
                >
                  {muscle.name}
                </button>
              <% end %>
            </div>

            <div class="space-y-2 max-h-96 overflow-y-auto">
              <%= for exercise <- @exercises do %>
                <%= if exercise.is_unilateral do %>
                  <div class="bg-white px-4 py-3 rounded-lg border border-gray-200">
                    <div class="flex items-center justify-between mb-2">
                      <span class="font-medium text-gray-800"><%= exercise.name %></span>
                      <span class="text-xs text-gray-500 bg-gray-100 px-2 py-1 rounded">Unilateral</span>
                    </div>
                    <div class="flex gap-2">
                      <button
                        phx-click="addExercise"
                        phx-value-id={exercise.id}
                        phx-value-side="left"
                        class="flex-1 bg-emerald-50 hover:bg-emerald-100 text-emerald-700 px-3 py-2 rounded text-sm font-medium transition-all"
                      >
                        + Left
                      </button>
                      <button
                        phx-click="addExercise"
                        phx-value-id={exercise.id}
                        phx-value-side="right"
                        class="flex-1 bg-emerald-50 hover:bg-emerald-100 text-emerald-700 px-3 py-2 rounded text-sm font-medium transition-all"
                      >
                        + Right
                      </button>
                    </div>
                  </div>
                <% else %>
                  <button
                    phx-click="addExercise"
                    phx-value-id={exercise.id}
                    class="w-full flex items-center justify-between bg-white hover:bg-emerald-50 px-4 py-3 rounded-lg border border-gray-200 hover:border-emerald-300 transition-all"
                  >
                    <span class="font-medium text-gray-800"><%= exercise.name %></span>
                    <span class="text-emerald-600 font-bold text-xl">+</span>
                  </button>
                <% end %>
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
              <div class="space-y-4">
                <%= for {exercise_id, sets} <- @workouts do %>
                  <div class="border border-gray-200 rounded-lg overflow-hidden">
                    <div class="bg-gray-50 px-4 py-3 flex items-center justify-between">
                      <h3 class="font-semibold text-gray-900">
                        <%= List.first(sets).data.exercise.name %>
                      </h3>
                      <span class="text-xs text-gray-500"><%= length(sets) %> sets</span>
                    </div>

                    <div class="divide-y divide-gray-100">
                      <%= for workout <- sets do %>
                        <.form
                          phx-change="updateExercise"
                          for={workout}
                          id={"workout-form-#{workout.data.id}"}
                          class="px-4 py-3"
                        >
                          <.input type="hidden" field={workout[:id]} />
                          <div class="grid grid-cols-1 lg:grid-cols-[auto,1fr,auto] items-start gap-3">
                            <div class="flex items-center gap-2 lg:pt-2">
                              <%= if workout.data.side != "both" do %>
                                <span class="text-sm font-semibold text-gray-700">Set <%= workout.data.set %> (<span class="capitalize"><%= workout.data.side %></span>)</span>
                              <% else %>
                                <span class="text-sm font-semibold text-gray-700">Set <%= workout.data.set %></span>
                              <% end %>
                            </div>

                            <div class="space-y-3">
                              <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                                <% is_amrap = workout.data.set_type && workout.data.set_type.name == "AMRAP" %>
                                <div class={[
                                  "rounded-lg border px-3 py-2",
                                  if(is_amrap, do: "border-gray-300 bg-gray-50", else: "border-gray-200 bg-white")
                                ]}>
                                  <p class="text-[11px] uppercase tracking-wide text-gray-400">
                                    Reps
                                    <%= if is_amrap do %>
                                      <span class="text-[10px] text-emerald-600 ml-1">(Max)</span>
                                    <% end %>
                                  </p>
                                  <div class="flex items-center gap-2 mt-1">
                                    <input
                                      type="number"
                                      name={"workout_details[reps]"}
                                      value={workout.data.reps}
                                      placeholder={if is_amrap, do: "Max reps", else: "0"}
                                      phx-debounce="500"
                                      disabled={is_amrap}
                                      class={[
                                        "w-full bg-transparent text-sm font-semibold focus:outline-none",
                                        if(is_amrap, do: "text-gray-400 cursor-not-allowed", else: "text-gray-900")
                                      ]}
                                    />
                                    <span class="text-xs text-gray-400">reps</span>
                                  </div>
                                </div>
                                <div class="rounded-lg border border-gray-200 bg-white px-3 py-2">
                                  <p class="text-[11px] uppercase tracking-wide text-gray-400">Weight</p>
                                  <div class="flex items-center gap-2 mt-1">
                                    <input
                                      type="text"
                                      name={"workout_details[weight]"}
                                      value={workout.data.weight}
                                      placeholder="0"
                                      phx-debounce="500"
                                      class="w-full bg-transparent text-sm font-semibold text-gray-900 focus:outline-none"
                                    />
                                    <span class="text-xs text-gray-400">kg</span>
                                  </div>
                                </div>
                              </div>

                              <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                                <div class="rounded-lg border border-gray-200 bg-white px-3 py-2">
                                  <p class="text-[11px] uppercase tracking-wide text-gray-400">Type</p>
                                  <select
                                    name={"workout_details[set_type_id]"}
                                    phx-debounce="500"
                                    class="w-full bg-transparent text-sm font-semibold text-gray-900 focus:outline-none mt-1"
                                  >
                                    <%= for type <- @setTypes do %>
                                      <option value={type.id} selected={workout.data.set_type_id == type.id}>
                                        <%= type.name %>
                                      </option>
                                    <% end %>
                                  </select>
                                </div>
                                <div class="rounded-lg border border-gray-200 bg-white px-3 py-2">
                                  <p class="text-[11px] uppercase tracking-wide text-gray-400">Notes</p>
                                  <input
                                    type="text"
                                    name={"workout_details[notes]"}
                                    value={workout.data.notes}
                                    placeholder="Optional notes"
                                    phx-debounce="500"
                                    class="w-full bg-transparent text-sm text-gray-900 focus:outline-none mt-1"
                                  />
                                </div>
                              </div>
                            </div>

                            <div class="flex items-center gap-2 justify-end lg:pt-2">
                              <button
                                type="button"
                                phx-click="deleteExercise"
                                data-confirm="Remove this set?"
                                phx-value-id={workout.data.id}
                                class="p-2 text-red-500 hover:bg-red-50 rounded-lg border border-red-100"
                                title="Remove"
                              >
                                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                                </svg>
                              </button>
                            </div>
                          </div>
                        </.form>
                      <% end %>
                    </div>

                    <div class="px-4 py-2 bg-gray-50 border-t border-gray-100">
                      <%= if List.first(sets).data.exercise.is_unilateral do %>
                        <div class="flex gap-2">
                          <button
                            type="button"
                            phx-click="addExercise"
                            phx-value-id={exercise_id}
                            phx-value-side="left"
                            class="flex-1 flex items-center justify-center gap-1 text-sm text-emerald-600 hover:text-emerald-700 font-medium py-1"
                          >
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>
                            </svg>
                            Add Left
                          </button>
                          <button
                            type="button"
                            phx-click="addExercise"
                            phx-value-id={exercise_id}
                            phx-value-side="right"
                            class="flex-1 flex items-center justify-center gap-1 text-sm text-emerald-600 hover:text-emerald-700 font-medium py-1"
                          >
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>
                            </svg>
                            Add Right
                          </button>
                        </div>
                      <% else %>
                        <button
                          type="button"
                          phx-click="addExercise"
                          phx-value-id={exercise_id}
                          class="w-full flex items-center justify-center gap-1 text-sm text-emerald-600 hover:text-emerald-700 font-medium py-1"
                        >
                          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>
                          </svg>
                          Add Set
                        </button>
                      <% end %>
                    </div>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>
        <!-- Programme loading -->



      <% else %>
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
              <%= if map_size(@muscle_group_frequencies) > 0 do %>
                <div class="mb-6 bg-white rounded-xl border border-gray-200 p-4">
                  <div class="flex items-center justify-between mb-3">
                    <div>
                      <h3 class="text-base font-semibold text-gray-900">Session Volume</h3>
                      <p class="text-xs text-gray-500">Direct vs effective sets per muscle</p>
                    </div>
                  </div>
                  <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-3">
                    <%= for {muscle_group, volumes} <- @muscle_group_frequencies do %>
                      <div class="bg-gradient-to-br from-emerald-50 to-white border border-emerald-100 rounded-lg px-3 py-2.5">
                        <p class="text-xs font-semibold text-slate-700 truncate"><%= muscle_group %></p>
                        <div class="flex items-center justify-between mt-2 text-[11px] text-slate-500">
                          <span>Direct</span>
                          <span class="inline-flex items-center justify-center px-2 py-0.5 bg-emerald-600 text-white text-xs font-semibold rounded-full">
                            <%= round(volumes.direct) %>
                          </span>
                        </div>
                        <div class="flex items-center justify-between mt-1 text-[11px] text-slate-500">
                          <span>Effective</span>
                          <span class="inline-flex items-center justify-center px-2 py-0.5 bg-emerald-100 text-emerald-700 text-xs font-semibold rounded-full">
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
                        <div class="bg-white rounded-lg border border-gray-200 p-3">
                          <div class="flex items-start justify-between">
                            <div class="flex items-start gap-4">
                              <!-- Set Number -->
                              <div class="flex flex-col">
                                <%= if workout.data.side != "both" do %>
                                  <span class="text-sm font-bold text-gray-900">Set <%= workout.data.set %></span>
                                  <span class="text-xs text-gray-500 capitalize"><%= workout.data.side %></span>
                                <% else %>
                                  <span class="text-sm font-bold text-gray-900">Set <%= workout.data.set %></span>
                                <% end %>
                              </div>

                              <!-- Stats -->
                              <div class="flex-1">
                                <div class="grid grid-cols-2 sm:grid-cols-3 gap-4 mb-2">
                                  <div>
                                    <p class="text-xs text-gray-500 uppercase tracking-wide">Reps</p>
                                    <p class="text-lg font-semibold text-gray-900"><%= workout.data.reps %></p>
                                  </div>
                                  <div>
                                    <p class="text-xs text-gray-500 uppercase tracking-wide">Weight</p>
                                    <p class="text-lg font-semibold text-gray-900"><%= workout.data.weight %> kg</p>
                                  </div>
                                    <div>
                                      <p class="text-xs text-gray-500 uppercase tracking-wide">Type</p>
                                      <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-purple-100 text-purple-700">
                                        <%= workout.data.set_type.name %>
                                      </span>
                                    </div>

                                </div>

                                <!-- Notes on separate line if exists -->
                                <%= if workout.data.notes && workout.data.notes != "" do %>
                                  <div class="mt-2 pt-2 border-t border-gray-100">
                                    <p class="text-xs text-gray-500 uppercase tracking-wide mb-1">Notes</p>
                                    <p class="text-sm text-gray-700 italic"><%= workout.data.notes %></p>
                                  </div>
                                <% end %>
                              </div>
                            </div>

                            <svg class="w-5 h-5 text-emerald-500 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
                              <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"></path>
                            </svg>
                          </div>
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

  defp build_workout_assigns(workouts) do
    changesets =
      Enum.map(workouts, fn workout ->
        workout |> Training.change_workout_details() |> to_form()
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
            # For bilateral: each row = 1 set (normal counting)
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

  defp normalize_workout_attrs(params) do
    params
    |> Map.take(["name", "date"])
    |> Map.update("date", nil, &parse_datetime_local/1)
  end

  defp parse_datetime_local(nil), do: nil
  defp parse_datetime_local(""), do: nil

  defp parse_datetime_local(value) do
    case NaiveDateTime.from_iso8601(value) do
      {:ok, naive} -> DateTime.from_naive!(naive, "Etc/UTC")
      _ -> value
    end
  end

  defp apply_exercise_filters(exercises, filter_applied, search) do
    exercises
    |> Enum.filter(fn ex ->
      filter_applied == "ALL" or (ex.muscle && ex.muscle.name == filter_applied)
    end)
    |> Enum.filter(fn ex ->
      search == "" ||
        String.contains?(String.downcase(ex.name || ""), String.downcase(search))
    end)
    |> Enum.sort_by(fn ex -> String.downcase(ex.name || "") end)
  end

  defp save_pending_changes(pending_changes) when map_size(pending_changes) == 0, do: :ok

  defp save_pending_changes(pending_changes) do
    results =
      Enum.map(pending_changes, fn {workout_detail_id, changes} ->
        case Repo.get(WorkoutDetails, workout_detail_id) do
          nil ->
            # Workout detail was deleted, skip silently
            {:ok, :skipped}
          workout_detail ->
            Training.update_workout_details(workout_detail, changes)
        end
      end)

    if Enum.all?(results, fn result -> match?({:ok, _}, result) end) do
      :ok
    else
      {:error, :some_updates_failed}
    end
  end
end
