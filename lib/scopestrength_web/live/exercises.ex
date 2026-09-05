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

defmodule ScopestrengthWeb.Exercises do
  use ScopestrengthWeb, :live_view

  import Ecto.Query

  alias Scopestrength.Exercise, as: ExerciseContext
  alias Scopestrength.Exercises
  alias Scopestrength.Exercises.Exercise
  alias Scopestrength.Trainers
  alias Scopestrength.Repo

  def handle_event("addExercise", params, socket) do
    user = socket.assigns.current_user
    primary_muscle_id = socket.assigns.selected_primary_muscle_id
    is_unilateral = params["exercise"]["is_unilateral"] == "true"

    attrs = %{
      name: params["exercise"]["name"],
      muscle_id: primary_muscle_id,
      equipment_id: params["exercise"]["equipment_id"],
      is_unilateral: is_unilateral,
      is_custom: true,
      user_id: user.id
    }

    case ExerciseContext.create_exercise(attrs) do
      {:ok, exercise} ->
        trainer = Trainers.get_trainer_byUserId(user.id)

        Exercises.create_exercise_muscle_contribution(%{
          exercise_id: exercise.id,
          muscle_id: primary_muscle_id,
          role: "primary",
          multiplier: 1.0,
          trainer_id: trainer.id
        })

        Enum.each(socket.assigns.secondary_muscles, fn muscle_id ->
          Exercises.create_exercise_muscle_contribution(%{
            exercise_id: exercise.id,
            muscle_id: muscle_id,
            role: "secondary",
            multiplier: 0.5,
            trainer_id: trainer.id
          })
        end)

        exercise = Repo.preload(exercise, [:muscle, :equipment])
        all_exercises = socket.assigns.allExercises ++ [exercise]

        exercises =
          apply_filters(
            all_exercises,
            socket.assigns.filterApplied,
            socket.assigns.searchExercise
          )

        {:noreply,
         socket
         |> assign(
           show_modal: false,
           allExercises: all_exercises,
           exercises: exercises,
           newExerciseForm: Exercise.changeset(%Exercise{}, %{}) |> to_form(),
           secondary_muscles: [],
           selected_primary_muscle_id: nil
         )
         |> put_flash(:info, "New exercise created")}

      _ ->
        {:noreply, socket |> put_flash(:error, "An error has occurred")}
    end
  end

  def handle_event("deleteExercise", %{"id" => id}, socket) do
    exercise_id = ScopestrengthWeb.Params.to_integer(id)
    exercise = ExerciseContext.get_exercise!(exercise_id)
    user = socket.assigns.current_user

    if exercise.is_custom and exercise.user_id == user.id do
    case ExerciseContext.delete_exercise(exercise) do
      {:ok, _} ->
        all_exercises = Enum.reject(socket.assigns.allExercises, &(&1.id == exercise_id))

        exercises =
          apply_filters(
            all_exercises,
            socket.assigns.filterApplied,
            socket.assigns.searchExercise
          )

        {:noreply,
         socket
         |> put_flash(:info, "Deleted successfully")
         |> assign(allExercises: all_exercises, exercises: exercises)}

      _ ->
        {:noreply, socket |> put_flash(:error, "Something happened")}
    end
    else
      {:noreply, socket |> put_flash(:error, "Exercise not found")}
    end
  end

  def handle_event("openModal", _params, socket) do
    show_modal = !socket.assigns.show_modal
    new_form = Exercise.changeset(%Exercise{}, %{}) |> to_form()

    {:noreply, assign(socket,
      show_modal: show_modal,
      newExerciseForm: new_form,
      secondary_muscles: [],
      selected_primary_muscle_id: nil
    )}
  end

  def handle_event("update_primary_muscle", %{"muscle_id" => id}, socket) do
    id = if id == "", do: nil, else: String.to_integer(id)
    secondary = Enum.reject(socket.assigns.secondary_muscles, &(&1 == id))
    {:noreply, assign(socket, selected_primary_muscle_id: id, secondary_muscles: secondary)}
  end

  def handle_event("toggle_secondary_muscle", %{"id" => id}, socket) do
    id = String.to_integer(id)
    secondary =
      if id in socket.assigns.secondary_muscles do
        Enum.reject(socket.assigns.secondary_muscles, &(&1 == id))
      else
        socket.assigns.secondary_muscles ++ [id]
      end
    {:noreply, assign(socket, secondary_muscles: secondary)}
  end

  def handle_event("editExercise", %{"id" => id}, socket) do
    exercise_id = String.to_integer(id)
    exercise = ExerciseContext.get_exercise!(exercise_id)
    edit_exercise_form = ExerciseContext.change_exercise(exercise) |> to_form()

    contributions =
      Repo.all(
        from ec in Scopestrength.Exercises.ExerciseMuscleContribution,
          where: ec.exercise_id == ^exercise_id
      )

    primary = Enum.find(contributions, &(&1.role == "primary"))
    secondary_ids = contributions |> Enum.filter(&(&1.role == "secondary")) |> Enum.map(&(&1.muscle_id))

    {:noreply, assign(socket,
      editExerciseForm: edit_exercise_form,
      show_edit_exercise: true,
      selected_primary_muscle_id: primary && primary.muscle_id,
      secondary_muscles: secondary_ids
    )}
  end

  def handle_event("saveExercise", params, socket) do
    IO.inspect(params)
    id = String.to_integer(params["exercise"]["id"])
    user = socket.assigns.current_user
    primary_muscle_id = socket.assigns.selected_primary_muscle_id
    is_unilateral = params["exercise"]["is_unilateral"] == "true"

    attrs = %{
      name: params["exercise"]["name"],
      muscle_id: primary_muscle_id,
      equipment_id: params["exercise"]["equipment_id"],
      is_unilateral: is_unilateral
    }

    exercise = ExerciseContext.get_exercise!(id)

    case ExerciseContext.update_exercise(exercise, attrs) do
      {:ok, updated_exercise} ->
        trainer = Trainers.get_trainer_byUserId(user.id)

        Repo.delete_all(
          from ec in Scopestrength.Exercises.ExerciseMuscleContribution,
            where: ec.exercise_id == ^updated_exercise.id
        )

        if primary_muscle_id do
          Exercises.create_exercise_muscle_contribution(%{
            exercise_id: updated_exercise.id,
            muscle_id: primary_muscle_id,
            role: "primary",
            multiplier: 1.0,
            trainer_id: trainer.id
          })
        end

        Enum.each(socket.assigns.secondary_muscles, fn muscle_id ->
          Exercises.create_exercise_muscle_contribution(%{
            exercise_id: updated_exercise.id,
            muscle_id: muscle_id,
            role: "secondary",
            multiplier: 0.5,
            trainer_id: trainer.id
          })
        end)

        updated_exercise = Repo.preload(updated_exercise, [:muscle, :equipment])

        updated_all =
          Enum.map(socket.assigns.allExercises, fn current ->
            if current.id == updated_exercise.id do
              updated_exercise
            else
              current
            end
          end)

        updated_filtered =
          apply_filters(updated_all, socket.assigns.filterApplied, socket.assigns.searchExercise)

        {:noreply,
         socket
         |> put_flash(:info, "Exercise updated")
         |> assign(
           exercises: updated_filtered,
           allExercises: updated_all,
           show_edit_exercise: false,
           selected_primary_muscle_id: nil,
           secondary_muscles: []
         )}

      _ ->
        {:noreply, socket |> put_flash(:error, "Error updating exercise")}
    end
  end

  def handle_event("closeEditExercise", _params, socket) do
    {:noreply, assign(socket,
      show_edit_exercise: false,
      selected_primary_muscle_id: nil,
      secondary_muscles: []
    )}
  end

  def handle_event("filterExercise", %{"name" => name}, socket) do
    filter_applied = name

    filtered =
      apply_filters(socket.assigns.allExercises, filter_applied, socket.assigns.searchExercise)

    {:noreply, assign(socket, exercises: filtered, filterApplied: filter_applied)}
  end

  def handle_event("searching", params, socket) do
    search = params["searchExercise"] || ""
    filtered = apply_filters(socket.assigns.allExercises, socket.assigns.filterApplied, search)

    {:noreply, assign(socket, exercises: filtered, searchExercise: search)}
  end

  def handle_event("resetFilters", _params, socket) do
    exercises = apply_filters(socket.assigns.allExercises, "All", "")
    {:noreply, assign(socket, exercises: exercises, filterApplied: "All", searchExercise: "")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    new_exercise_form = Exercise.changeset(%Exercise{}, %{}) |> to_form()
    edit_exercise_form = nil
    muscles = Exercises.list_mucles()
    equipment_list = Exercises.list_equipment()

    exercises =
      Repo.all(
        from e in Exercise,
          where: e.is_custom == false or e.user_id == ^user.id,
          order_by: [asc: e.name],
          preload: [:muscle, :equipment]
      )

    {:ok,
     assign(socket,
       searchExercise: "",
       editExerciseForm: edit_exercise_form,
       show_modal: false,
       show_edit_exercise: false,
       newExerciseForm: new_exercise_form,
       filterApplied: "All",
       allExercises: exercises,
       exercises: exercises,
       muscles: muscles,
       equipment_list: equipment_list,
       selected_primary_muscle_id: nil,
       secondary_muscles: []
     )}
  end

  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-6xl">
      <div class="flex flex-wrap items-end justify-between gap-4">
        <div>
          <p class="text-xs font-medium uppercase tracking-widest text-dim">Library</p>
          <h1 class="mt-1 font-display text-5xl font-bold uppercase tracking-wide text-foreground">
            Exercises
          </h1>
        </div>

        <.button phx-click="openModal" class="shrink-0">
          <span class="inline-flex items-center gap-2">
            <.icon name="hero-plus" class="h-4 w-4" /> Add exercise
          </span>
        </.button>
      </div>

      <form phx-change="searching" phx-debounce="250" class="mt-8">
        <input
          type="search"
          name="searchExercise"
          value={@searchExercise}
          placeholder="Search exercises or muscle groups"
          aria-label="Search exercises"
          class="w-full rounded-xl border-line bg-card px-5 py-4 text-base text-foreground placeholder:text-faint focus:border-primary focus:ring-0"
        />
      </form>

      <div :if={@exercises == []} class="mt-6 rounded-xl border border-dashed border-line px-6 py-16 text-center">
        <h3 class="font-display text-xl font-bold uppercase tracking-wide text-foreground">
          {if @allExercises == [], do: "No exercises yet", else: "No matches"}
        </h3>
        <p class="mx-auto mt-2 max-w-sm text-sm text-dim">
          {if @allExercises == [],
            do: "Create your first exercise to start building programmes.",
            else: "Try a different name or muscle group."}
        </p>
        <div class="mt-6">
          <.button :if={@allExercises == []} phx-click="openModal">Add your first exercise</.button>
          <button
            :if={@allExercises != []}
            type="button"
            phx-click="resetFilters"
            class="text-sm font-medium text-primary transition hover:opacity-80"
          >
            Clear search
          </button>
        </div>
      </div>

      <div :if={@exercises != []} class="mt-6 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
        <div
          :for={exercise <- @exercises}
          class="group relative flex flex-col rounded-xl border border-line bg-card p-5 transition hover:border-dim"
        >
          <h3 class="pr-8 font-semibold leading-snug text-foreground">{exercise.name}</h3>

          <div class="mt-3 flex flex-wrap gap-2">
            <.tag :if={exercise.muscle}>{exercise.muscle.name}</.tag>
            <.tag :if={exercise.equipment}>{exercise.equipment.name}</.tag>
            <.tag :if={exercise.is_unilateral}>Unilateral</.tag>
            <.tag :if={exercise.is_custom} tone="custom">Custom</.tag>
          </div>

          <div
            :if={exercise.is_custom}
            class="absolute right-3 top-3 flex items-center gap-1 opacity-0 transition focus-within:opacity-100 group-hover:opacity-100"
          >
            <button
              type="button"
              phx-click="editExercise"
              phx-value-id={exercise.id}
              aria-label={"Edit #{exercise.name}"}
              class="rounded-md p-1.5 text-dim transition hover:bg-secondary hover:text-foreground"
            >
              <.icon name="hero-pencil-square" class="h-4 w-4" />
            </button>
            <.confirm
              id={"delete-exercise-#{exercise.id}"}
              title="Delete Exercise"
              message={"Are you sure you want to delete #{exercise.name}? This action cannot be undone."}
              confirm_label="Delete"
              on_confirm={JS.push("deleteExercise", value: %{id: exercise.id})}
              aria-label={"Delete #{exercise.name}"}
              class="rounded-md p-1.5 text-dim transition hover:bg-danger/10 hover:text-danger"
            >
              <.icon name="hero-trash" class="h-4 w-4" />
            </.confirm>
          </div>
        </div>
      </div>

      <.exercise_modal
        :if={@show_modal}
        eyebrow="Create"
        title="New exercise"
        subtitle="Add a custom movement to your trainer library."
        submit="addExercise"
        close="openModal"
        form={@newExerciseForm}
        muscles={@muscles}
        equipment_list={@equipment_list}
        secondary_muscles={@secondary_muscles}
        selected_primary_muscle_id={@selected_primary_muscle_id}
        action_label="Create exercise"
      />

      <.exercise_modal
        :if={@show_edit_exercise}
        eyebrow="Edit"
        title="Update exercise"
        subtitle="Adjust naming, muscle, or equipment for this move."
        submit="saveExercise"
        close="closeEditExercise"
        form={@editExerciseForm}
        muscles={@muscles}
        equipment_list={@equipment_list}
        secondary_muscles={@secondary_muscles}
        selected_primary_muscle_id={@selected_primary_muscle_id}
        action_label="Save changes"
        editing
      />
    </div>
    """
  end

  attr :tone, :string, default: "default", values: ~w(default custom)
  slot :inner_block, required: true

  defp tag(assigns) do
    ~H"""
    <span class={[
      "num inline-flex items-center rounded-full border px-2.5 py-1 text-xs",
      @tone == "default" && "border-line text-dim",
      @tone == "custom" && "border-primary/40 text-primary"
    ]}>
      {render_slot(@inner_block)}
    </span>
    """
  end

  attr :eyebrow, :string, required: true
  attr :title, :string, required: true
  attr :subtitle, :string, required: true
  attr :submit, :string, required: true
  attr :close, :string, required: true
  attr :form, :any, required: true
  attr :muscles, :list, required: true
  attr :equipment_list, :list, required: true
  attr :secondary_muscles, :list, required: true
  attr :selected_primary_muscle_id, :any, default: nil
  attr :action_label, :string, required: true
  attr :editing, :boolean, default: false

  defp exercise_modal(assigns) do
    ~H"""
    <div class="fixed inset-0 z-50 overflow-y-auto">
      <div class="absolute inset-0 bg-black/70" phx-click={@close} aria-hidden="true"></div>
      <div class="relative flex min-h-full items-center justify-center p-4">
        <div
          role="dialog"
          aria-modal="true"
          class="w-full max-w-lg rounded-xl border border-line bg-card p-6 shadow-2xl"
        >
          <div class="flex items-start justify-between gap-3">
            <div>
              <p class="text-xs font-medium uppercase tracking-widest text-dim">{@eyebrow}</p>
              <h2 class="mt-1 font-display text-2xl font-bold uppercase tracking-wide text-foreground">
                {@title}
              </h2>
              <p class="mt-1 text-sm text-dim">{@subtitle}</p>
            </div>
            <button
              type="button"
              phx-click={@close}
              aria-label="Close"
              class="rounded-md p-1 text-dim transition hover:bg-secondary hover:text-foreground"
            >
              <.icon name="hero-x-mark" class="h-5 w-5" />
            </button>
          </div>

          <.form phx-submit={@submit} for={@form} class="mt-6 space-y-4">
            <input
              :if={@editing}
              type="hidden"
              name={@form[:id].name}
              value={Phoenix.HTML.Form.normalize_value("hidden", @form[:id].value)}
            />
            <.input
              type="text"
              required
              label="Exercise name"
              field={@form[:name]}
              placeholder="e.g. Single arm cable row"
            />

            <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <div>
                <label for="primary-muscle" class="mb-1 block text-sm font-medium text-foreground">
                  Primary muscle
                </label>
                <select
                  id="primary-muscle"
                  phx-change="update_primary_muscle"
                  name="muscle_id"
                  class="w-full rounded-md border-line bg-muted px-3 py-2 text-sm text-foreground focus:border-primary focus:ring-0"
                >
                  <option value="">Select muscle</option>
                  <option
                    :for={muscle <- @muscles}
                    value={muscle.id}
                    selected={@selected_primary_muscle_id == muscle.id}
                  >
                    {muscle.name}
                  </option>
                </select>
              </div>
              <.input
                type="select"
                options={Enum.map(@equipment_list, &{&1.name, &1.id})}
                field={@form[:equipment_id]}
                label="Equipment"
              />
            </div>

            <div :if={@editing}>
              <.input
                type="checkbox"
                field={@form[:is_unilateral]}
                label="Unilateral exercise (performed one side at a time)"
              />
            </div>
            <div :if={!@editing} class="flex items-center gap-2">
              <input
                type="checkbox"
                name="exercise[is_unilateral]"
                id="is_unilateral_new"
                value="true"
                class="h-4 w-4 rounded border-line bg-muted text-primary focus:ring-0"
              />
              <label for="is_unilateral_new" class="text-sm text-foreground">
                Unilateral exercise (performed one side at a time)
              </label>
            </div>

            <div>
              <label class="mb-2 block text-sm font-medium text-foreground">Secondary muscles</label>
              <p :if={is_nil(@selected_primary_muscle_id)} class="text-sm text-faint">
                Select a primary muscle first.
              </p>
              <div class="flex flex-wrap gap-2">
                <%= for muscle <- @muscles, muscle.id != @selected_primary_muscle_id do %>
                  <button
                    type="button"
                    phx-click="toggle_secondary_muscle"
                    phx-value-id={muscle.id}
                    aria-pressed={to_string(muscle.id in @secondary_muscles)}
                    class={[
                      "rounded-full px-3 py-1.5 text-xs font-medium transition",
                      muscle.id in @secondary_muscles && "bg-primary/15 text-primary",
                      muscle.id not in @secondary_muscles && "bg-muted text-dim hover:text-foreground"
                    ]}
                  >
                    {muscle.name}
                  </button>
                <% end %>
              </div>
            </div>

            <div class="flex items-center justify-end gap-3 border-t border-line pt-4">
              <button
                type="button"
                phx-click={@close}
                class="rounded-md px-4 py-2 text-sm font-medium text-dim transition hover:text-foreground"
              >
                Cancel
              </button>
              <.button>{@action_label}</.button>
            </div>
          </.form>
        </div>
      </div>
    </div>
    """
  end

  defp apply_filters(exercises, filter_applied, search) do
    exercises
    |> Enum.filter(fn ex ->
      filter_applied == "All" or (ex.muscle && ex.muscle.name == filter_applied)
    end)
    |> Enum.filter(&matches_search?(&1, search))
    |> Enum.sort_by(fn ex -> String.downcase(ex.name || "") end)
  end

  defp matches_search?(_exercise, ""), do: true

  defp matches_search?(exercise, search) do
    needle = String.downcase(search)

    [exercise.name, exercise.muscle && exercise.muscle.name, exercise.equipment && exercise.equipment.name]
    |> Enum.any?(fn value ->
      value && String.contains?(String.downcase(value), needle)
    end)
  end

end
