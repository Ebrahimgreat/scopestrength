defmodule CrohnjobsWeb.TemplateDetail do

alias Crohnjobs.CustomExercises
alias Crohnjobs.Trainers
alias Crohnjobs.CustomExercises.CustomExercise
  use CrohnjobsWeb, :live_view
  alias Crohnjobs.Programmes.ProgrammeDetails
  alias Crohnjobs.Repo
  alias Crohnjobs.Exercise
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
    trainer = Trainers.get_trainer_byUserId(user.id)
    name = params["custom_exercise"]["name"]
    type = params["custom_exercise"]["type"]
    equipment = params["custom_exercise"]["equipment"]
    case CustomExercises.create_custom_exercise(%{name: name, equipment: equipment, type: type, trainer_id: trainer.id}) do
      {:ok, customExercise}->
        exercises = socket.assigns.exercises ++ [customExercise]
      {:noreply,socket|> assign(show_modal: false, exercises: exercises)|> put_flash(:info, "exercise Created")}
      _ -> {:noreply, socket|> put_flash(:error, "An error has occured")}
    end
  end
  def handle_event("openModal", _, socket) do
    showModal = !socket.assigns.show_modal
    {:noreply, assign(socket, show_modal: showModal)}

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

    newExerciseForm = CustomExercise.changeset(%CustomExercise{}, %{})|> to_form()

    user = socket.assigns.current_user
    trainer = Trainers.get_trainer_byUserId(user.id)
    customExercises = Repo.all(from c in CustomExercise, where: c.trainer_id == ^trainer.id)


    template_id = params["template_id"]
    exercises = Exercise.list_exercises() ++ customExercises

    programmeTemplate =
      Repo.all(
        from pd in ProgrammeDetails,
          where: pd.programme_template_id == ^template_id,
          preload: [:exercise]
      )
      changesets = Enum.map(programmeTemplate, fn template-> template|> Programmes.change_programme_details()|> to_form() end)

      {:ok, assign(socket, newExerciseForm: newExerciseForm, show_modal: show_modal, template_id: template_id, programmeDetails: changesets, exercises: exercises)}

  end

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
  <div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
    <div class="bg-white p-6 rounded-lg w-96 relative">
      <h2 class="text-lg font-semibold mb-4">New Exercise</h2>
      <.form phx-submit="createExercise" for={@newExerciseForm}>

      <p> Create a new Exercise</p>
      <.input  type="text" required label="name" field={@newExerciseForm[:name]}/>
      <.input type="select" options = {["Chest","Back","Quads","Shoulders","Abs","Bicep","Tricep"]} field={@newExerciseForm[:type]}/>
      <.input type="select" field={@newExerciseForm[:equipment]} options={["Dumbell","Cable","Barbell", "Machine", "Plate"]}/>
      <.button>
      Submit
      </.button>




      </.form>
      <button phx-click="openModal" class="mt-4 bg-blue-600 text-white px-4 py-2 rounded">Close</button>

    </div>
  </div>
<% end %>
<button phx-click="openModal" class="bg-green-600 text-white px-4 py-2 rounded">Create Exercise</button>




        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
          <!-- Exercise Library Section -->
          <div class="bg-white rounded-xl shadow p-6 border">
            <div class="flex items-center justify-between mb-4">
              <h2 class="text-xl font-semibold text-gray-800">Exercise Library</h2>
              <span class="text-sm text-gray-500">
                <%= length(@exercises) %> available
              </span>
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
