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

defmodule ScopestrengthWeb.TemplateDetail do

alias Scopestrength.Trainers
  use ScopestrengthWeb, :live_view
  alias Scopestrength.Programmes.ProgrammeDetails
  alias Scopestrength.Repo
  alias Scopestrength.Exercise
  alias Scopestrength.Exercises
  alias Scopestrength.Programmes
  import Ecto.Query

  def handle_event("addExercise", params, socket) do


   exercise_id = String.to_integer(params["id"])
   programmeDetails = socket.assigns.programmeDetails
   IO.inspect(programmeDetails)
   exerciseFound = Enum.find(programmeDetails, fn x-> x.data.exercise_id == exercise_id end)
  case exerciseFound do
    nil ->
      newDetail = %{exercise_id: exercise_id, reps: "10", set: "1", programme_template_id: socket.assigns.template_id }
      case Programmes.create_programme_details(newDetail) do
        {:ok, programme}->
          programmeDetail = Programmes.get_programme_detail_with_exericse!(programme.id)
        form = Programmes.change_programme_details(programmeDetail) |> to_form()
          programmeDetails = programmeDetails ++ [form]
              {:noreply, assign(socket, programmeDetails: programmeDetails)}

      end
      _ -> {:noreply, socket}

  end




  end

  def handle_event("createExercise", params, socket) do
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

    case Exercise.create_exercise(attrs) do
      {:ok, exercise} ->
        trainer = Trainers.get_trainer_byUserId(user.id)

        if primary_muscle_id do
          Exercises.create_exercise_muscle_contribution(%{
            exercise_id: exercise.id,
            muscle_id: primary_muscle_id,
            role: "primary",
            multiplier: 1.0,
            trainer_id: trainer.id
          })
        end

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

        filtered_exercises =
          case socket.assigns.filter_by_type do
            "ALL" -> all_exercises
            filter -> Enum.filter(all_exercises, &(&1.muscle && &1.muscle.name == filter))
          end

        {:noreply,
         socket
         |> assign(
           show_modal: false,
           allExercises: all_exercises,
           exercises: filtered_exercises,
           newExerciseForm: Scopestrength.Exercises.Exercise.changeset(%Scopestrength.Exercises.Exercise{}, %{}) |> to_form(),
           secondary_muscles: [],
           selected_primary_muscle_id: nil
         )
         |> put_flash(:info, "New exercise created")}

      {:error, changeset} ->
        require Logger
        Logger.error("Failed to create exercise: #{inspect(changeset.errors)}")
        {:noreply, socket |> put_flash(:error, "Failed to create exercise. Please check all required fields.")}

      _ ->
        {:noreply, socket |> put_flash(:error, "An error has occurred")}
    end
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

  def handle_event("openModal", _, socket) do
    showModal = !socket.assigns.show_modal
    new_form = Scopestrength.Exercises.Exercise.changeset(%Scopestrength.Exercises.Exercise{}, %{}) |> to_form()

    {:noreply, assign(socket,
      show_modal: showModal,
      newExerciseForm: new_form,
      secondary_muscles: [],
      selected_primary_muscle_id: nil
    )}
  end



  def handle_event("filterByType", %{"name" => name}, socket) do
    if socket.assigns.filter_by_type == name do

      {:noreply, socket}
    else
      filtered_exercises =
        case name do
          "ALL" -> socket.assigns.allExercises
          _ -> Enum.filter(socket.assigns.allExercises, &(&1.muscle && &1.muscle.name == name))
        end

      {:noreply,
       assign(socket,
         exercises: filtered_exercises,
         filter_by_type: name
       )}
    end
  end

  def handle_event("searchExercises", %{"key" => _key, "value" => value}, socket) do
    q = String.trim(value || "")
    {:noreply, assign(socket, exercises: search_exercises(socket.assigns.allExercises, q), q: q)}
  end



  def handle_event("deleteExercise", params, socket) do
    id = ScopestrengthWeb.Params.to_integer(params["id"])
    programmeDetails = socket.assigns.programmeDetails
    programmeFind= Enum.find(programmeDetails,fn x-> x.data.id == id end)
 case Programmes.delete_programme_details(programmeFind.data) do
      {:ok, _programme}->
        updatedProgrammeDetail =  Enum.reject(programmeDetails, fn x-> x.data.id == id end)
      {:noreply, socket|> put_flash(:info, "Succesfully Deleted")|> assign(template_id: socket.assigns.template_id, programmeDetails: updatedProgrammeDetail, exercises: socket.assigns.exercises)}

      _ ->{:noreply,socket|> put_flash(:error, "Unsucessful")}


    end


  end


  def handle_event("updateForm", params, socket) do
    id = String.to_integer(params["programme_details"]["id"])
    reps = params["programme_details"]["reps"]
    set = params["programme_details"]["set"]
    min_reps= params["programme_details"]["min_reps"]
    max_reps = params["programme_details"]["max_reps"]
    programmeDetails = socket.assigns.programmeDetails

    programmeFind = Enum.find(programmeDetails, fn x-> x.data.id == id end)
   case Programmes.update_programme_details(programmeFind.data, %{set: set, reps: reps, min_reps: min_reps, max_reps: max_reps}) do
    {:ok,_updated}->
      programmeToUpdate = Enum.map(programmeDetails, fn x-> if x.data.id == id do
        updatedData= %{x.data | set: set, reps: reps, min_reps: min_reps, max_reps: max_reps}
        IO.inspect(updatedData)
        Programmes.change_programme_details(updatedData)|> to_form()
      else
        x
      end
    end)
      {:noreply,socket|> put_flash(:info, "Programme Detail updated")|> assign(template_id: socket.assigns.template_id, programmeDetails: programmeToUpdate, exercises: socket.assigns.exercises)}
     _ -> {:noreply, socket|> put_flash(:error, "Error has occured")}
   end



  end

  def mount(params, _session, socket) do
    if ScopestrengthWeb.TemplateAccess.owned_template?(params["template_id"], socket.assigns.current_user.id) do
      mount_template(params, socket)
    else
      {:ok,
       socket
       |> put_flash(:error, "Template not found")
       |> redirect(to: ~p"/trainer/programmes")}
    end
  end

  defp mount_template(params, socket) do

    _trainer_id = params["trainer_id"]
    show_modal = false



    newExerciseForm = Scopestrength.Exercises.Exercise.changeset(%Scopestrength.Exercises.Exercise{}, %{})|> to_form()

    user = socket.assigns.current_user
    _trainer = Trainers.get_trainer_byUserId(user.id)

    template_id = params["template_id"]

    muscles = Scopestrength.Exercises.list_mucles()
    equipment_list = Scopestrength.Exercises.list_equipment()

    exercises =
      Repo.all(
        from e in Scopestrength.Exercises.Exercise,
          where: e.is_custom == false or e.user_id == ^user.id,
          order_by: [asc: e.name],
          preload: [:muscle, :equipment]
      )



    programmeTemplate =
      Repo.all(
        from pd in ProgrammeDetails,
          where: pd.programme_template_id == ^template_id,
          preload: [:exercise]
      )
      changesets = Enum.map(programmeTemplate, fn template-> template|> Programmes.change_programme_details()|> to_form() end)

      socket =
      socket
      |> assign(allExercises: exercises, filter_by_type: "ALL", newExerciseForm: newExerciseForm, show_modal: show_modal, template_id: template_id, programme_id: params["id"], programmeDetails: changesets, exercises: exercises, muscles: muscles,  selected_primary_muscle_id: nil,
      secondary_muscles: [], equipment_list: equipment_list)
      |> assign_new(:q, fn -> "" end)

    {:ok, socket}

  end

  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
  defp search_exercises(exercises, ""), do: exercises

  defp search_exercises(exercises, query) do
    needle = String.downcase(query)

    Enum.filter(exercises, fn ex ->
      [ex.name, ex.muscle && ex.muscle.name, ex.equipment && ex.equipment.name]
      |> Enum.any?(fn value -> value && String.contains?(String.downcase(value), needle) end)
    end)
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-5xl">
      <div class="space-y-10">
        <.back_link navigate={~p"/trainer/programmes/#{@programme_id}"}>Programme</.back_link>
        <div>
          <h1 class="font-display text-5xl font-bold uppercase tracking-wide text-foreground">Template Builder</h1>
          <p class="text-dim">Add exercises and configure sets and reps for your workout template.</p>
        </div>

        <%= if @show_modal do %>
        <div class="fixed inset-0 z-50 flex items-center justify-center px-4">
          <div class="absolute inset-0 bg-card/60" aria-hidden="true"></div>
          <div class="relative bg-card rounded-2xl shadow-2xl w-full max-w-lg p-6">
            <div class="flex items-start justify-between gap-3">
              <div>
                <p class="text-xs uppercase tracking-[0.2em] text-faint">Create</p>
                <h2 class="text-xl font-semibold text-foreground">New exercise</h2>
                <p class="text-sm text-dim">Add a custom movement to your trainer library.</p>
              </div>
              <button
                phx-click="openModal"
                aria-label="Close"
                class="text-faint hover:text-dim"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-5 w-5"
                  viewBox="0 0 20 20"
                  fill="currentColor"
                >
                  <path
                    fill-rule="evenodd"
                    d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
                    clip-rule="evenodd"
                  />
                </svg>
              </button>
            </div>

            <.form phx-submit="createExercise" for={@newExerciseForm} class="mt-5 space-y-4">
              <.input
                type="text"
                required
                label="Exercise name"
                field={@newExerciseForm[:name]}
                placeholder="e.g. Single arm cable row"
              />
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label class="block text-sm font-medium text-foreground mb-1">Primary muscle</label>
                  <select
                    phx-change="update_primary_muscle"
                    name="muscle_id"
                    class="w-full rounded-lg border border-line bg-card px-3 py-2 text-sm focus:border-primary focus:ring-0 transition"
                  >
                    <option value="">Select muscle</option>
                    <%= for muscle <- @muscles do %>
                      <option value={muscle.id} selected={@selected_primary_muscle_id == muscle.id}>{muscle.name}</option>
                    <% end %>
                  </select>
                </div>
                <.input
                  type="select"
                  options={Enum.map(@equipment_list, &{&1.name, &1.id})}
                  field={@newExerciseForm[:equipment_id]}
                  label="Equipment"
                />
              </div>

              <div class="flex items-center gap-2 py-2">
                <input
                  type="checkbox"
                  name="exercise[is_unilateral]"
                  id="is_unilateral_new"
                  value="true"
                  class="h-4 w-4 rounded border-line bg-muted text-primary focus:ring-0"
                />
                <label for="is_unilateral_new" class="text-sm font-medium text-foreground">
                  Unilateral exercise (performed one side at a time)
                </label>
              </div>

              <div>
                <label class="block text-sm font-medium text-foreground mb-2">Secondary muscles</label>
                <div class="flex flex-wrap gap-2">
                  <%= for muscle <- @muscles do %>
                    <%= unless muscle.id == @selected_primary_muscle_id do %>
                      <button
                        type="button"
                        phx-click="toggle_secondary_muscle"
                        phx-value-id={muscle.id}
                        class={[
                          "px-3 py-1.5 rounded-full text-xs font-semibold border transition",
                          if(muscle.id in @secondary_muscles,
                            do: "bg-primary/10 text-primary border-primary",
                            else: "bg-card text-foreground border-line hover:bg-card"
                          )
                        ]}
                      >
                        {muscle.name}
                      </button>
                    <% end %>
                  <% end %>
                </div>
              </div>

              <div class="flex items-center justify-end gap-3 pt-2">
                <button
                  type="button"
                  phx-click="openModal"
                  class="px-4 py-2 rounded-lg bg-secondary text-foreground hover:bg-secondary"
                >
                  Cancel
                </button>
                <.button class="px-4 py-2 rounded-lg">
                  Create exercise
                </.button>
              </div>
            </.form>
          </div>
        </div>
      <% end %>
        <button
          phx-click="openModal"
          class="rounded-md bg-primary px-4 py-2 text-sm font-semibold text-primary-foreground transition hover:opacity-90"
        >
          Create Exercise
        </button>


        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
          <div class="rounded-xl border border-line bg-card p-5">
            <div class="mb-4 flex items-baseline justify-between gap-3">
              <h2 class="font-display text-xl font-bold uppercase tracking-wide text-foreground">
                Exercise Library
              </h2>
              <span class="num text-xs text-dim"><%= length(@exercises) %> available</span>
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

            <div class="max-h-96 space-y-2 overflow-y-auto">
              <button
                :for={exercise <- @exercises}
                phx-click="addExercise"
                phx-value-id={exercise.id}
                class="flex w-full items-center justify-between gap-3 rounded-lg border border-line px-4 py-3 text-left transition hover:border-primary"
              >
                <span class="min-w-0">
                  <span class="block truncate font-medium text-foreground">
                    <%= exercise.name %>
                  </span>
                  <span :if={exercise.muscle} class="num mt-0.5 block text-xs text-dim">
                    <%= exercise.muscle.name %>
                  </span>
                </span>
                <.icon name="hero-plus" class="h-4 w-4 shrink-0 text-faint" />
              </button>
            </div>
          </div>

          <div class="rounded-xl border border-line bg-card p-5">
            <div class="mb-4 flex items-baseline justify-between gap-3">
              <h2 class="font-display text-xl font-bold uppercase tracking-wide text-foreground">
                Template
              </h2>
              <span class="num text-xs text-dim">
                <%= length(@programmeDetails) %> exercise<%= if length(@programmeDetails) != 1, do: "s" %>
              </span>
            </div>

            <%= if length(@programmeDetails) > 0 do %>
              <div class="space-y-6 max-h-96 overflow-y-auto">
                <%= for {template, index} <- Enum.with_index(@programmeDetails) do %>
                  <div class="rounded-lg border border-line p-4">
                    <div class="mb-3 flex items-center justify-between gap-3">
                      <h3 class="min-w-0 truncate font-medium text-foreground">
                        <span class="num text-faint"><%= index + 1 %></span>
                        <%= template.data.exercise.name %>
                      </h3>
                      <.confirm
                        id={"remove-exercise-#{template.data.id}"}
                        title="Remove Exercise"
                        message="Are you sure you want to remove this exercise from the template?"
                        confirm_label="Remove"
                        on_confirm={JS.push("deleteExercise", value: %{id: template.data.id})}
                        aria-label="Remove exercise"
                        class="shrink-0 rounded-md p-1.5 text-dim transition hover:bg-danger/10 hover:text-danger"
                      >
                        <.icon name="hero-trash" class="h-4 w-4" />
                      </.confirm>
                    </div>

                    <.form phx-submit="updateForm" for={template} id={"exercise-form-#{template.data.id}"} class="space-y-4">
                      <input type="hidden" name={template[:id].name} value={template[:id].value} />

                      <div class="grid grid-cols-4 gap-4">
                        <div>
                          <label class="block text-xs uppercase tracking-widest text-dim">Sets</label>
                          <.input
                            field={template[:set]}
                            id={"set-#{template.data.id}"}
                            type="number"
                            min="1"
                            class="num mt-1 block w-full rounded-md border-line bg-muted px-3 py-2 text-sm text-foreground placeholder:text-faint focus:border-primary focus:ring-0"
                          />
                        </div>
                        <div>
                          <label class="block text-xs uppercase tracking-widest text-dim">Reps</label>
                          <.input
                            field={template[:reps]}
                            id={"reps-#{template.data.id}"}
                            type="text"
                            placeholder="e.g., 10, 8-12, AMRAP"
                            class="num mt-1 block w-full rounded-md border-line bg-muted px-3 py-2 text-sm text-foreground placeholder:text-faint focus:border-primary focus:ring-0"
                          />
                        </div>
                        <div>
                      <label class="block text-xs uppercase tracking-widest text-dim">
                      Min Reps
                      <.input field={template[:min_reps]}
                      id={"min-reps-#{template.data.id}"}
                      type="number"
                      placeholder="4"
                      class="num mt-1 block w-full rounded-md border-line bg-muted px-3 py-2 text-sm text-foreground placeholder:text-faint focus:border-primary focus:ring-0"
                      />


                      </label>
                      </div>
                      <div>
                      <label class="block text-xs uppercase tracking-widest text-dim">
                      Max Reps
                      <.input field={template[:max_reps]}
                      id={"max-reps-#{template.data.id}"}
                      type="number"
                      placeholder="4"
                      class="num mt-1 block w-full rounded-md border-line bg-muted px-3 py-2 text-sm text-foreground placeholder:text-faint focus:border-primary focus:ring-0"
                      />


                      </label>
                      </div>
                      </div>


                      <div class="flex justify-end">
                        <.button class="px-4 py-2 rounded-md text-sm font-medium">
                          Update
                        </.button>
                      </div>
                    </.form>
                  </div>
                <% end %>
              </div>
            <% else %>
              <div class="text-center py-12 bg-card rounded-lg border">
                <h3 class="text-lg font-medium text-foreground mb-2">No exercises added yet</h3>
                <p class="text-dim">Start building your template by adding exercises from the library.</p>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end


end
