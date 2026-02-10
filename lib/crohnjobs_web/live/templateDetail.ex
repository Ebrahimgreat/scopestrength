defmodule CrohnjobsWeb.TemplateDetail do

alias Crohnjobs.CustomExercises
alias Crohnjobs.Trainers
alias Crohnjobs.CustomExercises.CustomExercise
  use CrohnjobsWeb, :live_view
  alias Crohnjobs.Programmes.ProgrammeDetails
  alias Crohnjobs.Repo
  alias Crohnjobs.Exercise
  alias Crohnjobs.Exercises
  alias Crohnjobs.Programmes
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
           newExerciseForm: Crohnjobs.Exercises.Exercise.changeset(%Crohnjobs.Exercises.Exercise{}, %{}) |> to_form(),
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
    new_form = Crohnjobs.Exercises.Exercise.changeset(%Crohnjobs.Exercises.Exercise{}, %{}) |> to_form()

    {:noreply, assign(socket,
      show_modal: showModal,
      newExerciseForm: new_form,
      secondary_muscles: [],
      selected_primary_muscle_id: nil
    )}
  end



  def handle_event("filterByType", %{"name" => name}, socket) do
    # prevent redundant reload
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

    filtered =
      socket.assigns.allExercises
      |> Enum.filter(fn ex ->
        String.contains?(String.downcase(ex.name || ""), String.downcase(q || ""))
      end)

    {:noreply, assign(socket, exercises: filtered, q: q)}
  end


  def handle_event("deleteExercise", params, socket) do
    id = String.to_integer(params["id"])
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
    programmeDetails = socket.assigns.programmeDetails

    programmeFind = Enum.find(programmeDetails, fn x-> x.data.id == id end)
   case Programmes.update_programme_details(programmeFind.data, %{set: set, reps: reps}) do
    {:ok,_updated}->
      programmeToUpdate = Enum.map(programmeDetails, fn x-> if x.data.id == id do
        updatedData= %{x.data | set: set, reps: reps}
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

  def mount(params, session, socket) do

    trainer_id = params["trainer_id"]
    show_modal = false



    newExerciseForm = Crohnjobs.Exercises.Exercise.changeset(%Crohnjobs.Exercises.Exercise{}, %{})|> to_form()

    user = socket.assigns.current_user
    trainer = Trainers.get_trainer_byUserId(user.id)

    template_id = params["template_id"]

    muscles = Crohnjobs.Exercises.list_mucles()
    equipment_list = Crohnjobs.Exercises.list_equipment()

    exercises =
      Repo.all(
        from e in Crohnjobs.Exercises.Exercise,
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
      |> assign(allExercises: exercises, filter_by_type: "ALL", newExerciseForm: newExerciseForm, show_modal: show_modal, template_id: template_id, programmeDetails: changesets, exercises: exercises, muscles: muscles,  selected_primary_muscle_id: nil,
      secondary_muscles: [], equipment_list: equipment_list)
      |> assign_new(:q, fn -> "" end)

    {:ok, socket}

  end

  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 py-10">
      <div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 space-y-10">
        <!-- Header -->
        <div>
          <h1 class="text-3xl font-bold text-gray-900 mb-2">Template Exercise Builder</h1>
          <p class="text-gray-600">Add exercises and configure sets and reps for your workout template.</p>
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
                <div>
                  <label class="block text-sm font-medium text-slate-700 mb-1">Primary muscle</label>
                  <select
                    phx-change="update_primary_muscle"
                    name="muscle_id"
                    class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500 transition"
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
                  class="w-4 h-4 text-emerald-600 border-gray-300 rounded focus:ring-emerald-500"
                />
                <label for="is_unilateral_new" class="text-sm font-medium text-slate-700">
                  Unilateral exercise (performed one side at a time)
                </label>
              </div>

              <div>
                <label class="block text-sm font-medium text-slate-700 mb-2">Secondary muscles</label>
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
                            do: "bg-emerald-50 text-emerald-700 border-emerald-200",
                            else: "bg-white text-slate-700 border-slate-200 hover:bg-slate-50"
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
<button phx-click="openModal" class="bg-green-600 text-white px-4 py-2 rounded">Create Exercise</button>

<div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
    <!-- Filter By Type -->
    <div>
      <h3 class="text-sm font-medium text-gray-700 mb-3 flex items-center">
        <svg class="w-4 h-4 mr-2 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z"></path>
        </svg>
        Filter By Type
      </h3>

      <p class="text-sm text-gray-700 mb-2 flex items-center gap-2">
        Applied: <span class="inline-block bg-blue-100 text-blue-800 font-semibold px-2 py-0.5 rounded"><%= if @filter_by_type == "ALL", do: "All types", else: @filter_by_type %></span>
        <%= if @filter_by_type != "ALL" do %>
          <button phx-click="filterByType" phx-value-name="ALL" class="text-sm text-red-600 font-medium hover:underline">
            Reset
          </button>
        <% end %>
      </p>
      <div class="flex flex-wrap gap-2">
        <button
          phx-click="filterByType"
          phx-value-name="ALL"
          class={[
            "px-4 py-2 rounded-md text-sm font-medium transition-all duration-200",
            if(@filter_by_type == "ALL",
              do: "bg-blue-600 text-white shadow-md",
              else: "bg-white border border-gray-300 text-gray-800 hover:bg-gray-100 hover:shadow-sm"
            )
          ]}
        >
          All Types
        </button>

        <%= for muscle <- @muscles do %>
          <button
            phx-click="filterByType"
            phx-value-name={muscle.name}
            class={[
              "px-4 py-2 rounded-md text-sm font-medium transition-all duration-200",
              if(@filter_by_type == muscle.name,
                do: "bg-blue-600 text-white shadow-md",
                else: "bg-white border border-gray-300 text-gray-800 hover:bg-gray-100 hover:shadow-sm"
              )
            ]}
          >
            {muscle.name}
          </button>
        <% end %>
      </div>
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
                  class="w-full flex items-center justify-between px-4 py-3 text-left hover:bg-gray-100 transition"
                >
                  <span class="font-medium text-gray-800"><%= exercise.name %></span>
                  <span class="text-green-600 font-bold text-lg">+</span>
                </button>
              <% end %>
            </div>
          </div>

          <!-- Template Configuration Section -->
          <div class="bg-white rounded-xl shadow p-6 border">
            <div class="flex items-center justify-between mb-4">
              <h2 class="text-xl font-semibold text-gray-800">Template Configuration</h2>
              <span class="text-sm text-gray-500">
                <%= length(@programmeDetails) %> exercise<%= if length(@programmeDetails) != 1, do: "s" %>
              </span>
            </div>

            <%= if length(@programmeDetails) > 0 do %>
              <div class="space-y-6 max-h-96 overflow-y-auto">
                <%= for {template, index} <- Enum.with_index(@programmeDetails) do %>
                  <div class="p-4 bg-gray-50 rounded-lg border">
                    <div class="flex items-center justify-between mb-3">
                      <h3 class="font-semibold text-gray-900">
                        <%= index + 1 %>. <%= template.data.exercise.name %>
                      </h3>
                      <.button
                        phx-click="deleteExercise"
                        phx-value-id={template.data.id}
                        data-confirm="Are you sure you want to remove this exercise?"
                        class="text-red-600 hover:underline text-sm"
                      >
                        Remove
                      </.button>
                    </div>

                    <.form phx-submit="updateForm" for={template} id={"exercise-form-#{template.data.id}"} class="space-y-4">
                      <.input type="hidden" field={template[:id]} />

                      <div class="grid grid-cols-2 gap-4">
                        <div>
                          <label class="block text-sm font-medium text-gray-700">Sets</label>
                          <.input
                            field={template[:set]}
                            id={"set-#{template.data.id}"}
                            type="number"
                            min="1"
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                          />
                        </div>
                        <div>
                          <label class="block text-sm font-medium text-gray-700">Reps</label>
                          <.input
                            field={template[:reps]}
                            id={"reps-#{template.data.id}"}
                            type="text"
                            placeholder="e.g., 10, 8-12, AMRAP"
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                          />
                        </div>
                      </div>

                      <div class="flex justify-end">
                        <.button class="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-md text-sm font-medium shadow-sm">
                          Update
                        </.button>
                      </div>
                    </.form>
                  </div>
                <% end %>
              </div>
            <% else %>
              <!-- Empty State -->
              <div class="text-center py-12 bg-gray-50 rounded-lg border">
                <h3 class="text-lg font-medium text-gray-900 mb-2">No exercises added yet</h3>
                <p class="text-gray-600">Start building your template by adding exercises from the library.</p>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end


end
