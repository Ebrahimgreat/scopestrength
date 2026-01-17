defmodule CrohnjobsWeb.Exercises do
  use CrohnjobsWeb, :live_view

  import Ecto.Query

  alias Crohnjobs.Exercise, as: ExerciseContext
  alias Crohnjobs.Exercises.Exercise
  alias Crohnjobs.Repo

  def handle_event("addExercise", params, socket) do
    user = socket.assigns.current_user

    attrs = %{
      name: params["exercise"]["name"],
      equipment: params["exercise"]["equipment"],
      type: params["exercise"]["type"],
      is_custom: true,
      user_id: user.id
    }

    case ExerciseContext.create_exercise(attrs) do
      {:ok, exercise} ->
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
           newExerciseForm: Exercise.changeset(%Exercise{}, %{}) |> to_form()
         )
         |> put_flash(:info, "New exercise created")}

      _ ->
        {:noreply, socket |> put_flash(:error, "An error has occurred")}
    end
  end

  def handle_event("deleteExercise", %{"id" => id}, socket) do
    exercise_id = String.to_integer(id)
    exercise = ExerciseContext.get_exercise!(exercise_id)

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
  end

  def handle_event("openModal", _params, socket) do
    show_modal = !socket.assigns.show_modal
    new_form = Exercise.changeset(%Exercise{}, %{}) |> to_form()

    {:noreply, assign(socket, show_modal: show_modal, newExerciseForm: new_form)}
  end

  def handle_event("editExercise", %{"id" => id}, socket) do
    exercise = ExerciseContext.get_exercise!(id)
    edit_exercise_form = ExerciseContext.change_exercise(exercise) |> to_form()

    {:noreply, assign(socket, editExerciseForm: edit_exercise_form, show_edit_exercise: true)}
  end

  def handle_event("saveExercise", params, socket) do
    id = String.to_integer(params["exercise"]["id"])

    attrs = %{
      name: params["exercise"]["name"],
      type: params["exercise"]["type"],
      equipment: params["exercise"]["equipment"]
    }

    exercise = ExerciseContext.get_exercise!(id)

    case ExerciseContext.update_exercise(exercise, attrs) do
      {:ok, updated_exercise} ->
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
           show_edit_exercise: false
         )}

      _ ->
        {:noreply, socket |> put_flash(:error, "Error updating exercise")}
    end
  end

  def handle_event("closeEditExercise", _params, socket) do
    {:noreply, assign(socket, show_edit_exercise: false)}
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

    exercises =
      Repo.all(
        from e in Exercise,
          where: e.is_custom == false or e.user_id == ^user.id,
          order_by: [asc: e.name]
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
       exercises: exercises
     )}
  end

  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-slate-50">
      <div class="bg-gradient-to-r from-emerald-600 to-teal-600 text-white">
        <div class="max-w-6xl mx-auto px-6 py-8">
          <% custom_count = Enum.count(@allExercises, & &1.is_custom) %>
          <% library_count = length(@allExercises) - custom_count %>
          <div class="flex items-start justify-between gap-6">
            <div>
              <p class="text-sm uppercase tracking-[0.2em] text-emerald-100 mb-2">
                Trainers · Exercises
              </p>
              <h1 class="text-3xl font-bold leading-tight">Exercise Library</h1>
              <p class="mt-2 text-emerald-50">
                Update, filter, and manage every movement in one place.
              </p>
              <div class="mt-4 flex flex-wrap gap-3 text-sm">
                <span class="inline-flex items-center gap-2 bg-white/10 px-3 py-1 rounded-full border border-white/20">
                  <span class="w-2 h-2 rounded-full bg-white"></span> Total {length(@allExercises)}
                </span>
                <span class="inline-flex items-center gap-2 bg-white/10 px-3 py-1 rounded-full border border-white/20">
                  <span class="w-2 h-2 rounded-full bg-amber-300"></span> Custom {custom_count}
                </span>
                <span class="inline-flex items-center gap-2 bg-white/10 px-3 py-1 rounded-full border border-white/20">
                  <span class="w-2 h-2 rounded-full bg-emerald-300"></span> Library {library_count}
                </span>
              </div>
            </div>
            <div class="flex flex-col gap-3 items-end">
              <.button
                phx-click="openModal"
                class="bg-white text-emerald-700 hover:bg-emerald-50 px-5 py-2.5 rounded-lg font-medium shadow-sm"
              >
                + Add exercise
              </.button>
            </div>
          </div>
        </div>
      </div>

      <div class="max-w-6xl mx-auto px-6 py-8 space-y-6">
        <div class="bg-white border border-slate-200 rounded-xl shadow-sm p-5 space-y-4">
          <div class="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
            <div class="w-full lg:w-1/2">
              <form phx-change="searching" phx-debounce="250" class="space-y-1">
                <label class="text-sm font-medium text-slate-600">Search exercises</label>
                <div class="relative">
                  <span
                    class="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400"
                    aria-hidden="true"
                  >
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      class="h-4 w-4"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M21 21l-4.35-4.35m0 0A7.5 7.5 0 103.5 10.5a7.5 7.5 0 0013.15 6.15z"
                      />
                    </svg>
                  </span>
                  <input
                    type="search"
                    name="searchExercise"
                    value={@searchExercise}
                    placeholder="Search by name"
                    class="w-full rounded-lg border border-slate-200 bg-slate-50 focus:bg-white pl-10 pr-3 py-2 text-sm shadow-inner focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500 transition"
                  />
                </div>
              </form>
            </div>

            <div class="flex flex-wrap gap-2">
              <.button
                phx-click="resetFilters"
                class="bg-slate-100 text-slate-700 hover:bg-slate-200 px-3 py-2 rounded-lg text-sm font-medium"
              >
                Reset filters
              </.button>
              <.button
                phx-click="filterExercise"
                phx-value-name="All"
                class={[
                  "px-3 py-2 rounded-lg text-sm font-medium transition",
                  if(@filterApplied == "All",
                    do: "bg-emerald-600 text-white shadow-sm",
                    else: "bg-slate-100 text-slate-700 hover:bg-slate-200"
                  )
                ]}
              >
                All types
              </.button>
            </div>
          </div>

          <div class="flex flex-wrap gap-2">
            <%= for type <- Enum.drop(type_options(), 1) do %>
              <button
                type="button"
                phx-click="filterExercise"
                phx-value-name={type}
                class={[
                  "px-3 py-1.5 rounded-full text-xs font-semibold border transition",
                  if(@filterApplied == type,
                    do: "bg-emerald-50 text-emerald-700 border-emerald-200 shadow-sm",
                    else: "bg-white text-slate-700 border-slate-200 hover:bg-slate-50"
                  )
                ]}
              >
                {type}
              </button>
            <% end %>
          </div>

          <div class="flex items-center justify-between text-sm text-slate-600 pt-2">
            <span>
              Showing {length(@exercises)} exercise{if length(@exercises) != 1, do: "s"}
              <%= if @filterApplied != "All" do %>
                for "{@filterApplied}"
              <% end %>
            </span>
            <%= if length(@exercises) == 0 do %>
              <span class="text-amber-600 font-medium">No exercises match the current filters</span>
            <% end %>
          </div>
        </div>

        <div class="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
          <%= if length(@exercises) > 0 do %>
            <div class="overflow-x-auto">
              <table class="w-full text-sm">
                <thead class="bg-slate-50 border-b border-slate-200">
                  <tr>
                    <th class="text-left py-3 px-6 font-semibold text-slate-800">Exercise</th>
                    <th class="text-left py-3 px-6 font-semibold text-slate-800">Type</th>
                    <th class="text-left py-3 px-6 font-semibold text-slate-800">Equipment</th>
                    <th class="text-left py-3 px-6 font-semibold text-slate-800">Source</th>
                    <th class="text-right py-3 px-6 font-semibold text-slate-800">Actions</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-slate-200">
                  <%= for exercise <- @exercises do %>
                    <tr class="hover:bg-slate-50 transition">
                      <td class="py-4 px-6">
                        <div class="font-semibold text-slate-900">{exercise.name}</div>
                      </td>
                      <td class="py-4 px-6">
                        <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold bg-emerald-50 text-emerald-700 border border-emerald-100">
                          {exercise.type || "N/A"}
                        </span>
                      </td>
                      <td class="py-4 px-6 text-slate-700">
                        {exercise.equipment || "None"}
                      </td>
                      <td class="py-4 px-6">
                        <span class={[
                          "inline-flex items-center gap-2 text-xs font-semibold px-2.5 py-1 rounded-full border",
                          if(exercise.is_custom,
                            do: "bg-amber-50 text-amber-700 border-amber-100",
                            else: "bg-slate-100 text-slate-700 border-slate-200"
                          )
                        ]}>
                          <span class={[
                            "w-2 h-2 rounded-full",
                            if(exercise.is_custom, do: "bg-amber-500", else: "bg-slate-400")
                          ]}>
                          </span>
                          {if exercise.is_custom, do: "Custom", else: "Library"}
                        </span>
                      </td>
                      <td class="py-4 px-6 text-right">
                        <%= if exercise.is_custom do %>
                          <div class="flex items-center gap-2 justify-end">
                            <button
                              type="button"
                              phx-click="editExercise"
                              phx-value-id={exercise.id}
                              class="px-3 py-1.5 text-xs font-semibold rounded-lg bg-slate-100 text-slate-700 hover:bg-slate-200"
                            >
                              Edit
                            </button>
                            <button
                              type="button"
                              phx-click="deleteExercise"
                              phx-value-id={exercise.id}
                              class="px-3 py-1.5 text-xs font-semibold rounded-lg bg-rose-50 text-rose-700 hover:bg-rose-100"
                            >
                              Delete
                            </button>
                          </div>
                        <% else %>
                          <span class="text-xs text-slate-400">Read only</span>
                        <% end %>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          <% else %>
            <div class="text-center py-12">
              <svg
                class="w-16 h-16 mx-auto text-slate-300 mb-4"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                >
                </path>
              </svg>
              <h3 class="text-lg font-semibold text-slate-900 mb-1">No exercises yet</h3>
              <p class="text-slate-500 mb-4">
                Create your first exercise to start building programmes.
              </p>
              <.button
                type="button"
                phx-click="openModal"
                class="bg-emerald-600 hover:bg-emerald-700 text-white px-6 py-2 rounded-lg font-medium transition"
              >
                Add your first exercise
              </.button>
            </div>
          <% end %>
        </div>
      </div>

      <%= if @show_modal do %>
        <div class="fixed inset-0 z-50 flex items-center justify-center px-4">
          <div class="absolute inset-0 bg-slate-900/60" aria-hidden="true"></div>
          <div class="relative bg-white rounded-2xl shadow-2xl w-full max-w-lg p-6">
            <div class="flex items-start justify-between gap-3">
              <div>
                <p class="text-xs uppercase tracking-[0.2em] text-slate-400">Create</p>
                <h2 class="text-xl font-semibold text-slate-900">New exercise</h2>
                <p class="text-sm text-slate-500">Add a custom movement to your trainer library.</p>
              </div>
              <button
                phx-click="openModal"
                aria-label="Close"
                class="text-slate-400 hover:text-slate-600"
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

            <.form phx-submit="addExercise" for={@newExerciseForm} class="mt-5 space-y-4">
              <.input
                type="text"
                required
                label="Exercise name"
                field={@newExerciseForm[:name]}
                placeholder="e.g. Single arm cable row"
              />
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <.input
                  type="select"
                  options={Enum.drop(type_options(), 1)}
                  field={@newExerciseForm[:type]}
                  label="Muscle group"
                />
                <.input
                  type="select"
                  options={equipment_options()}
                  field={@newExerciseForm[:equipment]}
                  label="Equipment"
                />
              </div>

              <div class="flex items-center justify-end gap-3 pt-2">
                <button
                  type="button"
                  phx-click="openModal"
                  class="px-4 py-2 rounded-lg bg-slate-100 text-slate-700 hover:bg-slate-200"
                >
                  Cancel
                </button>
                <.button class="bg-emerald-600 hover:bg-emerald-700 px-4 py-2 rounded-lg">
                  Create exercise
                </.button>
              </div>
            </.form>
          </div>
        </div>
      <% end %>

      <%= if @show_edit_exercise do %>
        <div class="fixed inset-0 z-50 flex items-center justify-center px-4">
          <div class="absolute inset-0 bg-slate-900/60" aria-hidden="true"></div>
          <div class="relative bg-white rounded-2xl shadow-2xl w-full max-w-lg p-6">
            <div class="flex items-start justify-between gap-3">
              <div>
                <p class="text-xs uppercase tracking-[0.2em] text-slate-400">Edit</p>
                <h2 class="text-xl font-semibold text-slate-900">Update exercise</h2>
                <p class="text-sm text-slate-500">Adjust naming, type, or equipment for this move.</p>
              </div>
              <button
                phx-click="closeEditExercise"
                aria-label="Close"
                class="text-slate-400 hover:text-slate-600"
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

            <.form phx-submit="saveExercise" for={@editExerciseForm} class="mt-5 space-y-4">
              <.input type="hidden" field={@editExerciseForm[:id]} />
              <.input type="text" required label="Exercise name" field={@editExerciseForm[:name]} />
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <.input
                  type="select"
                  options={Enum.drop(type_options(), 1)}
                  field={@editExerciseForm[:type]}
                  label="Muscle group"
                />
                <.input
                  type="select"
                  options={equipment_options()}
                  field={@editExerciseForm[:equipment]}
                  label="Equipment"
                />
              </div>

              <div class="flex items-center justify-end gap-3 pt-2">
                <button
                  type="button"
                  phx-click="closeEditExercise"
                  class="px-4 py-2 rounded-lg bg-slate-100 text-slate-700 hover:bg-slate-200"
                >
                  Cancel
                </button>
                <.button class="bg-emerald-600 hover:bg-emerald-700 px-4 py-2 rounded-lg">
                  Save changes
                </.button>
              </div>
            </.form>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp apply_filters(exercises, filter_applied, search) do
    exercises
    |> Enum.filter(fn ex ->
      filter_applied == "All" or (ex.type && ex.type == filter_applied)
    end)
    |> Enum.filter(fn ex ->
      search == "" ||
        String.contains?(String.downcase(ex.name || ""), String.downcase(search))
    end)
    |> Enum.sort_by(fn ex -> String.downcase(ex.name || "") end)
  end

  defp type_options do
    [
      "All",
      "Chest",
      "Back",
      "Quads",
      "Hamstrings",
      "Glutes",
      "Shoulders",
      "Abs",
      "Bicep",
      "Tricep"
    ]
  end

  defp equipment_options do
    ["Dumbbell", "Cable", "Barbell", "Machine", "Plate","Body Weight"]
  end
end
