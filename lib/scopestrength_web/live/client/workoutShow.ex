# ScopeStrength - personal trainer management application
# Copyright (C) 2026  Ebrahim Shahid Arshad
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# SPDX-License-Identifier: AGPL-3.0-or-later

defmodule ScopestrengthWeb.Client.WorkoutShow do
alias Scopestrength.ClientProgressions
alias Scopestrength.Programmes.ProgrammeUser
alias Scopestrength.Training
alias Scopestrength.Training.Workout
alias Scopestrength.Exercises.Exercise
alias Scopestrength.Exercises.ExerciseMuscleContribution
alias Scopestrength.Exercises
  use ScopestrengthWeb, :live_view
  alias Scopestrength.Repo
  import Ecto.Query
  alias Scopestrength.Clients.Client
  alias Scopestrength.Training.WorkoutDetails


  def handle_event("addExercise", params, socket) do
    exercise_id = String.to_integer(params["id"])

    existing_sets = Map.get(socket.assigns.workouts, exercise_id, [])
    next_set = length(existing_sets) + 1

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
        workout_details = Repo.preload(workout_details, [:exercise])

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

    rir =
      case Float.parse(params["workout_details"]["rir"] || "") do
        {num, _} -> num
        :error -> 0.0
      end

    rpe =
      case Float.parse(params["workout_details"]["rpe"] || "") do
        {num, _} -> num
        :error -> nil
      end

    pending_changes = Map.put(
      socket.assigns.pending_changes,
      workout_detail_id,
      %{reps: reps, weight: weight, rir: rir, rpe: rpe}
    )

    updated_workouts =
      socket.assigns.workouts
      |> Enum.map(fn {exercise_id, sets} ->
        updated_sets = Enum.map(sets, fn workout_form ->
          if workout_form.data.id == workout_detail_id do
            updated_data = %{workout_form.data | reps: reps, weight: weight, rir: rir, rpe: rpe}
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
    case save_pending_changes(socket.assigns.pending_changes, socket.assigns.client.id) do
      {:ok, saved} ->
        {:noreply,
         socket
         |> assign(workouts: refresh_workouts(socket.assigns.workouts, saved))
         |> assign(pending_changes: %{}, has_unsaved_changes: false)
         |> put_flash(:info, "All changes saved successfully")}

      {:error, _reason} ->
        {:noreply, socket |> put_flash(:error, "Failed to save some changes")}
    end
  end

  def handle_event("auto_save_on_leave", _params, socket) do
    if socket.assigns.has_unsaved_changes do
      save_pending_changes(socket.assigns.pending_changes, socket.assigns.client.id)
    end
    {:noreply, socket}
  end


  def handle_event("searchExercises", %{"key" => _key, "value" => value}, socket) do
    q = String.trim(value || "")
    {:noreply, assign(socket, exercises: search_exercises(socket.assigns.allExercises, q), q: q)}
  end

  def handle_event("deleteExercise", %{"id" => id_param}, socket) do
    case Integer.parse(to_string(id_param)) do
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
                    updated |> Repo.preload([:exercise]) |> Training.change_workout_details() |> to_form()
                  else
                    workout_form
                  end
                end)
              end)
              |> Enum.reject(fn {_exercise_id, sets} -> Enum.empty?(sets) end)
              |> Map.new()

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
    socket = if socket.assigns.edit_mode and socket.assigns.has_unsaved_changes do
      case save_pending_changes(socket.assigns.pending_changes, socket.assigns.client.id) do
        {:ok, saved} ->
          socket
          |> assign(workouts: refresh_workouts(socket.assigns.workouts, saved))
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
            if detail.exercise.is_unilateral do
              left_attrs = %{
                workout_id: workout_id,
                exercise_id: detail.exercise_id,
                set: 1,
                side: "left",
                reps: 10,
                weight: nil
              }

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
            |> Repo.preload([:exercise])

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

  def handle_event("load_from_own_programme", %{"template-id" => template_id}, socket) do
    workout_id = socket.assigns.workout_id

    template =
      socket.assigns.own_programmes
      |> Enum.flat_map(& &1.programmeTemplates)
      |> Enum.find(&("#{&1.id}" == template_id))

    if template do
      result =
        Repo.transaction(fn ->
          Repo.delete_all(from w in WorkoutDetails, where: w.workout_id == ^workout_id)

          template.programmeDetails
          |> Enum.uniq_by(& &1.exercise_id)
          |> Enum.each(fn detail ->
            if detail.exercise.is_unilateral do
              case Training.create_workout_details(%{workout_id: workout_id, exercise_id: detail.exercise_id, set: 1, side: "left", reps: 10, weight: nil}) do
                {:ok, _} ->
                  case Training.create_workout_details(%{workout_id: workout_id, exercise_id: detail.exercise_id, set: 1, side: "right", reps: 10, weight: nil}) do
                    {:ok, _} -> :ok
                    {:error, changeset} -> Repo.rollback(changeset)
                  end
                {:error, changeset} -> Repo.rollback(changeset)
              end
            else
              case Training.create_workout_details(%{workout_id: workout_id, exercise_id: detail.exercise_id, set: 1, reps: 10, weight: nil}) do
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
            |> Repo.preload([:exercise])

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
    client = Repo.get_by(Scopestrength.Clients.Client, %{user_id: user.id})

    trainer = case client.trainer_id do
      nil -> nil
      trainer_id -> Repo.get_by(Scopestrength.Trainers.Trainer, %{id: trainer_id})
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

    muscles = Exercises.list_mucles()

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
                  )|>Repo.preload([:exercise])

                  IO.inspect(workouts)

                {grouped_workouts, muscle_group_frequencies} = build_workout_assigns(workouts)

                  programme =
                    Repo.get_by(ProgrammeUser, %{
                      client_id: client.id,
                      is_active: true
                    })|>Repo.preload(programme: [programmeTemplates: [programmeDetails: :exercise]])

                  own_programmes =
                    Repo.all(
                      from p in Scopestrength.Programmes.Programme,
                        where: p.user_id == ^user.id,
                        preload: [programmeTemplates: [programmeDetails: :exercise]]
                    )

                  newForm = WorkoutDetails.changeset(%WorkoutDetails{},%{})|>to_form()

                {:ok,
                 socket
                 |> assign(:client, client)
                 |>assign(:programme, programme)
                 |>assign(:own_programmes, own_programmes)
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
            <.link navigate={~p"/client"} phx-click="auto_save_on_leave" class="text-dim hover:text-foreground">
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"></path>
              </svg>
            </.link>
            <h1 class="text-3xl font-bold text-foreground">Workout Details</h1>
            <%= if @has_unsaved_changes do %>
              <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-warning/10 text-warning">
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
                class="bg-primary hover:bg-primary/90 text-primary-foreground px-6 py-3 rounded-xl shadow-lg transition-all duration-200"
              >
                <svg class="w-5 h-5 inline mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
                </svg>
                Save All Changes
              </.button>
            <% end %>
            <.button
              phx-click="toggle_edit_mode"
              class={"#{if @edit_mode, do: "bg-secondary hover:bg-secondary/90 text-foreground border border-line", else: "bg-primary hover:bg-primary/90 text-primary-foreground"} px-6 py-3 rounded-xl shadow-lg transition-all duration-200"}
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
        <div class="mb-8 bg-card rounded-xl shadow-lg p-6 border border-line">
          <h2 class="text-lg font-semibold text-foreground">Update Workout</h2>
          <.form for={@workout_form} phx-submit="update_workout" class="mt-4 space-y-4 max-w-xl">
            <div>
              <label class="block text-sm font-medium text-foreground">Name</label>
              <.input
                field={@workout_form[:name]}
                type="text"
                class="w-full px-3 py-2 border border-line rounded-md text-sm"
                placeholder="Workout name"
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-foreground">Date</label>
              <.input
                field={@workout_form[:date]}
                type="datetime-local"
                class="w-full px-3 py-2 border border-line rounded-md text-sm"
              />
              <p class="text-xs text-dim mt-1">Stored in UTC.</p>
            </div>
            <.button class="px-4 py-2 text-sm">
              Save
            </.button>
          </.form>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
          <div class="bg-card rounded-xl shadow-lg p-6 border border-line">
            <%= if @programme && @programme.programme && length(@programme.programme.programmeTemplates) > 0 do %>
              <div class="mb-6 rounded-lg border border-line bg-muted p-4">
                <h2 class="text-sm font-semibold text-foreground">Load from programme</h2>
                <p class="mt-0.5 text-xs text-dim">
                  Replaces current workout with 1 set per exercise.
                </p>
                <div class="mt-3 grid grid-cols-1 gap-2 sm:grid-cols-2">
                  <%= for template <- @programme.programme.programmeTemplates do %>
                    <.confirm
                      id={"load-template-#{template.id}"}
                      title="Replace Workout"
                      message="This will replace your current workout with this template. Continue?"
                      confirm_label="Replace"
                      on_confirm={JS.push("load_from_programme", value: %{"template-id" => template.id})}
                      class="flex items-center justify-between gap-2 rounded-md border border-line px-3 py-2 text-xs font-medium text-dim transition hover:border-primary hover:text-primary"
                    >
                      <span class="truncate"><%= template.name %></span>
                      <.icon name="hero-arrow-down-tray" class="h-3.5 w-3.5 shrink-0" />
                    </.confirm>
                  <% end %>
                </div>
              </div>
            <% end %>

            <%= if length(@own_programmes) > 0 do %>
              <div class="mb-6 rounded-lg border border-line bg-muted p-4">
                <h2 class="text-sm font-semibold text-foreground">Load from my programmes</h2>
                <p class="mt-0.5 text-xs text-dim">
                  Replaces current workout with 1 set per exercise.
                </p>
                <%= for programme <- @own_programmes do %>
                  <p class="mb-2 mt-3 text-xs uppercase tracking-widest text-faint">
                    <%= programme.name %>
                  </p>
                  <div class="grid grid-cols-1 gap-2 sm:grid-cols-2">
                    <%= for template <- programme.programmeTemplates do %>
                      <.confirm
                        id={"load-own-template-#{template.id}"}
                        title="Replace Workout"
                        message="This will replace your current workout with this template. Continue?"
                        confirm_label="Replace"
                        on_confirm={
                          JS.push("load_from_own_programme", value: %{"template-id" => template.id})
                        }
                        class="flex items-center justify-between gap-2 rounded-md border border-line px-3 py-2 text-xs font-medium text-dim transition hover:border-primary hover:text-primary"
                      >
                        <span class="truncate"><%= template.name %></span>
                        <.icon name="hero-arrow-down-tray" class="h-3.5 w-3.5 shrink-0" />
                      </.confirm>
                    <% end %>
                  </div>
                <% end %>
              </div>
            <% end %>

            <div class="mb-4 flex items-baseline justify-between gap-3">
              <h2 class="font-display text-xl font-bold uppercase tracking-wide text-foreground">
                Exercise Library
              </h2>
              <span class="num text-xs text-dim">{length(@exercises)} available</span>
            </div>

            <div class="mb-4">
              <input
                type="search"
                name="q"
                id="exercise-search"
                value={@q}
                phx-debounce="300"
                phx-keyup="searchExercises"
                placeholder="Search exercises or muscle groups"
                aria-label="Search exercises"
                class="w-full rounded-md border-line bg-muted px-4 py-2.5 text-sm text-foreground placeholder:text-faint focus:border-primary focus:ring-0"
              />
            </div>

            <div class="space-y-2 max-h-96 overflow-y-auto">
              <%= for exercise <- @exercises do %>
                <%= if exercise.is_unilateral do %>
                  <div class="bg-card px-4 py-3 rounded-lg border border-line">
                    <div class="flex items-center justify-between mb-2">
                      <span class="font-medium text-foreground"><%= exercise.name %></span>
                      <span class="text-xs text-dim bg-secondary px-2 py-1 rounded">Unilateral</span>
                    </div>
                    <div class="flex gap-2">
                      <button
                        phx-click="addExercise"
                        phx-value-id={exercise.id}
                        phx-value-side="left"
                        class="flex-1 bg-primary/10 hover:bg-primary/10 text-primary px-3 py-2 rounded text-sm font-medium transition-all"
                      >
                        + Left
                      </button>
                      <button
                        phx-click="addExercise"
                        phx-value-id={exercise.id}
                        phx-value-side="right"
                        class="flex-1 bg-primary/10 hover:bg-primary/10 text-primary px-3 py-2 rounded text-sm font-medium transition-all"
                      >
                        + Right
                      </button>
                    </div>
                  </div>
                <% else %>
                  <button
                    phx-click="addExercise"
                    phx-value-id={exercise.id}
                    class="w-full flex items-center justify-between bg-card hover:bg-primary/10 px-4 py-3 rounded-lg border border-line hover:border-primary transition-all"
                  >
                    <span class="font-medium text-foreground"><%= exercise.name %></span>
                    <span class="text-primary font-bold text-xl">+</span>
                  </button>
                <% end %>
              <% end %>
            </div>
          </div>

          <div class="bg-card rounded-xl shadow-lg p-6 border border-line">
            <h2 class="text-xl font-semibold text-foreground mb-4">Workout Configuration</h2>

            <%= if Enum.empty?(@workouts) do %>
              <div class="text-center py-12">
                <div class="w-16 h-16 bg-secondary rounded-full flex items-center justify-center mx-auto mb-4">
                  <svg class="w-8 h-8 text-faint" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
                  </svg>
                </div>
                <p class="text-dim">Add exercises from the library to start building your workout</p>
              </div>
            <% else %>
              <div class="space-y-4">
                <%= for {exercise_id, sets} <- @workouts do %>
                  <div class="overflow-hidden rounded-lg border border-line">
                    <div class="border-b border-line px-4 py-3">
                      <h3 class="font-semibold text-primary">
                        <%= List.first(sets).data.exercise.name %>
                      </h3>
                    </div>

                    <div class="hidden px-4 pt-3 sm:grid sm:grid-cols-[2rem,1fr,1fr,1fr,1fr,2rem] sm:gap-3">
                      <span class="text-[11px] uppercase tracking-widest text-faint">Set</span>
                      <span class="text-[11px] uppercase tracking-widest text-faint">Weight (kg)</span>
                      <span class="text-[11px] uppercase tracking-widest text-faint">Reps</span>
                      <span class="text-[11px] uppercase tracking-widest text-faint">RIR</span>
                      <span class="text-[11px] uppercase tracking-widest text-faint">RPE</span>
                      <span class="sr-only">Remove</span>
                    </div>

                    <div>
                      <%= for workout <- sets do %>
                        <.form
                          phx-change="updateExercise"
                          for={workout}
                          id={"workout-form-#{workout.data.id}"}
                          class="px-4 py-2"
                        >
                          <input type="hidden" name={workout[:id].name} value={workout[:id].value} />

                          <div class="grid grid-cols-2 gap-2 sm:grid-cols-[2rem,1fr,1fr,1fr,1fr,2rem] sm:items-center sm:gap-3">
                            <span class="num text-sm text-dim">
                              <span class="sm:hidden">Set </span>{workout.data.set}
                            </span>

                            <label class="flex flex-col gap-1 sm:contents">
                              <span class="text-[10px] uppercase tracking-widest text-faint sm:hidden">Weight (kg)</span>
                            <label class="flex flex-col gap-1 sm:contents">
                              <span class="text-[10px] uppercase tracking-widest text-faint sm:hidden">Reps</span>
                            <label class="flex flex-col gap-1 sm:contents">
                              <span class="text-[10px] uppercase tracking-widest text-faint sm:hidden">RIR</span>
                            <label class="flex flex-col gap-1 sm:contents">
                              <span class="text-[10px] uppercase tracking-widest text-faint sm:hidden">RPE</span>
                            <input
                              type="text"
                              inputmode="decimal"
                              name={"workout_details[weight]"}
                              value={workout.data.weight}
                              placeholder="0"
                              aria-label="Weight in kilograms"
                              phx-debounce="500"
                              class="num w-full rounded-md border-0 bg-muted px-3 py-2.5 text-base text-foreground placeholder:text-faint focus:ring-2 focus:ring-inset focus:ring-primary"
                            />
                            </label>

                            <input
                              type="number"
                              inputmode="numeric"
                              name={"workout_details[reps]"}
                              value={workout.data.reps}
                              placeholder="0"
                              aria-label="Reps"
                              phx-debounce="500"
                              class="num w-full rounded-md border-0 bg-muted px-3 py-2.5 text-base text-foreground placeholder:text-faint focus:ring-2 focus:ring-inset focus:ring-primary"
                            />
                            </label>

                            <input
                              type="number"
                              inputmode="decimal"
                              name={"workout_details[rir]"}
                              value={workout.data.rir}
                              placeholder="0"
                              min="0"
                              step="0.5"
                              aria-label="Reps in reserve"
                              phx-debounce="500"
                              class="num w-full rounded-md border-0 bg-muted px-3 py-2.5 text-base text-foreground placeholder:text-faint focus:ring-2 focus:ring-inset focus:ring-primary"
                            />
                            </label>

                            <input
                              type="number"
                              inputmode="decimal"
                              name={"workout_details[rpe]"}
                              value={workout.data.rpe}
                              placeholder="—"
                              min="1"
                              max="10"
                              step="0.5"
                              aria-label="Rate of perceived exertion"
                              phx-debounce="500"
                              class="num w-full rounded-md border-0 bg-muted px-3 py-2.5 text-base text-foreground placeholder:text-faint focus:ring-2 focus:ring-inset focus:ring-primary"
                            />
                            </label>

                            <.confirm
                              id={"remove-set-#{workout.data.id}"}
                              title="Remove Set"
                              message="Are you sure you want to remove this set?"
                              confirm_label="Remove"
                              on_confirm={JS.push("deleteExercise", value: %{id: workout.data.id})}
                              aria-label={"Remove set #{workout.data.set}"}
                              class="col-span-2 mt-1 inline-flex w-fit items-center gap-1 rounded-md px-2 py-1 text-xs text-faint transition hover:bg-danger/10 hover:text-danger sm:col-span-1 sm:mt-0 sm:p-1.5 sm:text-sm"
                            >
                              <.icon name="hero-x-mark" class="h-4 w-4" /><span class="sm:hidden">Remove set</span>
                            </.confirm>
                          </div>

                          <div
                            :if={workout.data.side != "both"}
                            class="mt-1 grid grid-cols-[2rem,1fr] gap-3"
                          >
                            <span class="col-start-2 inline-flex w-fit items-center rounded-full bg-secondary px-2 py-0.5 text-[10px] uppercase tracking-widest text-dim">
                              {workout.data.side}
                            </span>
                          </div>
                        </.form>
                      <% end %>
                    </div>

                    <div class="px-4 pb-3 pt-1">
                      <%= if List.first(sets).data.exercise.is_unilateral do %>
                        <div class="flex gap-2">
                          <button
                            :for={side <- ~w(left right)}
                            type="button"
                            phx-click="addExercise"
                            phx-value-id={exercise_id}
                            phx-value-side={side}
                            class="num flex-1 rounded-md border border-line px-3 py-2 text-xs uppercase tracking-widest text-dim transition hover:border-primary hover:text-primary"
                          >
                            + Add {side}
                          </button>
                        </div>
                      <% else %>
                        <button
                          type="button"
                          phx-click="addExercise"
                          phx-value-id={exercise_id}
                          class="num rounded-md border border-line px-3 py-2 text-xs uppercase tracking-widest text-dim transition hover:border-primary hover:text-primary"
                        >
                          + Add set
                        </button>
                      <% end %>
                    </div>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>



      <% else %>
        <div class="bg-card rounded-2xl shadow-lg border border-line">
          <%= if Enum.empty?(@workouts) do %>
            <div class="text-center py-16">
              <div class="w-20 h-20 bg-secondary rounded-full flex items-center justify-center mx-auto mb-4">
                <svg class="w-10 h-10 text-faint" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"></path>
                </svg>
              </div>
              <h3 class="text-lg font-medium text-foreground mb-2">No Exercises Yet</h3>
              <p class="text-dim mb-4">Click "Edit Workout" to add exercises to this workout</p>
            </div>
          <% else %>
            <div class="p-6">
              <%= if map_size(@muscle_group_frequencies) > 0 do %>
                <div class="mb-6 bg-card rounded-xl border border-line p-4">
                  <div class="flex items-center justify-between mb-3">
                    <div>
                      <h3 class="text-base font-semibold text-foreground">Session Volume</h3>
                      <p class="text-xs text-dim">Direct vs effective sets per muscle</p>
                    </div>
                  </div>
                  <% session_max =
                    @muscle_group_frequencies
                    |> Enum.map(fn {_m, v} -> v.effective end)
                    |> Enum.max(fn -> 0.0 end) %>
                  <div class="space-y-2.5">
                    <%= for {muscle_group, volumes} <- Enum.sort_by(@muscle_group_frequencies, fn {_m, v} -> v.effective end, :desc) do %>
                      <% indirect = max(volumes.effective - volumes.direct, 0.0) %>
                      <div>
                        <div class="flex items-baseline justify-between gap-3">
                          <span class="truncate text-sm text-foreground"><%= muscle_group %></span>
                          <span class="num shrink-0 text-xs text-dim">
                            <span class="text-foreground"><%= round(volumes.direct) %></span>
                            <span :if={indirect > 0}> + <%= round(indirect) %></span>
                          </span>
                        </div>
                        <div class="mt-1.5 h-1.5 w-full overflow-hidden rounded-full bg-muted">
                          <div class="flex h-full">
                            <div
                              class="h-full rounded-l-full bg-primary"
                              style={"width: #{bar_pct(volumes.direct, session_max)}%"}
                            >
                            </div>
                            <div
                              class="h-full bg-primary/30"
                              style={"width: #{bar_pct(indirect, session_max)}%"}
                            >
                            </div>
                          </div>
                        </div>
                      </div>
                    <% end %>
                  </div>
                </div>
              <% end %>
              <div class="space-y-4">
                <%= for {_exercise_id, sets} <- @workouts do %>
                  <div class="overflow-hidden rounded-lg border border-line">
                    <div class="flex items-baseline justify-between gap-3 border-b border-line px-4 py-3">
                      <h3 class="font-semibold text-primary">
                        <%= List.first(sets).data.exercise.name %>
                      </h3>

                      <% progressed = status_count(sets, "progress") %>
                      <% reduced = status_count(sets, "reduce") %>

                      <div class="flex items-center gap-2">
                        <span
                          :if={progressed > 0}
                          class="inline-flex items-center rounded-full border border-primary/40 px-2 py-0.5 text-[10px] uppercase tracking-widest text-primary"
                        >
                          <%= progressed %> progressed
                        </span>
                        <span
                          :if={reduced > 0}
                          class="inline-flex items-center rounded-full border border-danger/40 px-2 py-0.5 text-[10px] uppercase tracking-widest text-danger"
                        >
                          <%= reduced %> reduced
                        </span>
                        <span class="num text-xs text-dim"><%= length(sets) %> sets</span>
                      </div>
                    </div>

                    <div class="hidden sm:grid grid-cols-[2rem,1fr,1fr,1fr,1fr] gap-3 px-4 pt-3">
                      <span class="text-[11px] uppercase tracking-widest text-faint">Set</span>
                      <span class="text-[11px] uppercase tracking-widest text-faint">Weight</span>
                      <span class="text-[11px] uppercase tracking-widest text-faint">Reps</span>
                      <span class="text-[11px] uppercase tracking-widest text-faint">RIR</span>
                      <span class="text-[11px] uppercase tracking-widest text-faint">RPE</span>
                    </div>

                    <div class="px-4 pb-3">
                      <%= for workout <- sets do %>
                        <div class="flex flex-wrap items-baseline gap-x-4 gap-y-1 border-b border-line/60 py-2.5 last:border-0 sm:grid sm:grid-cols-[2rem,1fr,1fr,1fr,1fr] sm:gap-3">
                          <span class="num text-sm text-dim"><span class="sm:hidden">Set </span><%= workout.data.set %></span>
                          <span class="num text-base text-foreground">
                            <%= workout.data.weight %><span class="ml-1 text-xs text-faint">kg</span>
                          </span>
                          <span class="num text-base text-foreground"><%= workout.data.reps %><span class="ml-1 text-xs text-faint sm:hidden">reps</span></span>
                          <span class="num text-base text-foreground"><span class="mr-1 text-xs text-faint sm:hidden">RIR</span><%= workout.data.rir || 0 %></span>
                          <span class="num text-base text-foreground">
                            <span class="mr-1 text-xs text-faint sm:hidden">RPE</span><%= if workout.data.rpe, do: workout.data.rpe, else: "—" %>
                          </span>
                          <div
                            :if={workout.data.side != "both" or workout.data.progression_status in ["progress", "reduce"]}
                            class="flex basis-full items-center gap-2 sm:col-start-2 sm:-mt-1 sm:w-fit sm:basis-auto"
                          >
                            <span
                              :if={workout.data.side != "both"}
                              class="inline-flex items-center rounded-full bg-secondary px-2 py-0.5 text-[10px] uppercase tracking-widest text-dim"
                            >
                              <%= workout.data.side %>
                            </span>
                            <span
                              :if={workout.data.progression_status in ["progress", "reduce"]}
                              class={[
                                "inline-flex items-center rounded-full border px-2 py-0.5 text-[10px] uppercase tracking-widest",
                                workout.data.progression_status == "progress" && "border-primary/40 text-primary",
                                workout.data.progression_status == "reduce" && "border-danger/40 text-danger"
                              ]}
                            >
                              <%= workout.data.progression_status %>
                            </span>
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

  defp status_count(sets, status) do
    Enum.count(sets, fn workout -> workout.data.progression_status == status end)
  end

  defp bar_pct(_value, max) when max <= 0, do: 0
  defp bar_pct(value, max), do: Float.round(value / max * 100, 2)

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
            Enum.flat_map(details, fn _detail ->
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
    attrs = Map.take(params, ["name", "date"])

    case parse_datetime_local(attrs["date"]) do
      %DateTime{} = date -> Map.put(attrs, "date", date)
      _ -> Map.delete(attrs, "date")
    end
  end

  defp parse_datetime_local(nil), do: nil
  defp parse_datetime_local(""), do: nil

  defp parse_datetime_local(value) do
    case NaiveDateTime.from_iso8601(value) do
      {:ok, naive} -> DateTime.from_naive!(naive, "Etc/UTC")
      _ -> value
    end
  end

  defp search_exercises(exercises, ""), do: exercises

  defp search_exercises(exercises, query) do
    needle = String.downcase(query)

    Enum.filter(exercises, fn ex ->
      [ex.name, ex.muscle && ex.muscle.name, ex.equipment && ex.equipment.name]
      |> Enum.any?(fn value -> value && String.contains?(String.downcase(value), needle) end)
    end)
  end

  defp refresh_workouts(workouts, saved) when map_size(saved) == 0, do: workouts

  defp refresh_workouts(workouts, saved) do
    Map.new(workouts, fn {exercise_id, sets} ->
      sets =
        Enum.map(sets, fn workout_form ->
          case Map.fetch(saved, workout_form.data.id) do
            {:ok, detail} -> detail |> Training.change_workout_details() |> to_form()
            :error -> workout_form
          end
        end)

      {exercise_id, sets}
    end)
  end

  defp save_pending_changes(pending_changes, _client_id) when map_size(pending_changes) == 0,
    do: {:ok, %{}}

  defp save_pending_changes(pending_changes, client_id) do
    results =
      Enum.map(pending_changes, fn {workout_detail_id, changes} ->
        case Repo.get(WorkoutDetails, workout_detail_id) do
          nil ->
            {:ok, :skipped}

          workout_detail ->
            case Training.update_workout_details(workout_detail, changes) do
              {:ok, updated_workout_detail} ->
                ClientProgressions.process_workout_detail(client_id, updated_workout_detail)

                {:ok, Repo.get(WorkoutDetails, updated_workout_detail.id) |> Repo.preload(:exercise)}

              {:error, changeset} ->
                {:error, changeset}
            end
        end
      end)

    if Enum.all?(results, fn result -> match?({:ok, _}, result) end) do
      saved =
        for {:ok, %WorkoutDetails{} = detail} <- results,
            into: %{},
            do: {detail.id, detail}

      {:ok, saved}
    else
      {:error, :some_updates_failed}
    end
  end
end
