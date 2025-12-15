defmodule CrohnjobsWeb.ExerciseProgress do
  alias Crohnjobs.Strength
  alias CrohnjobsWeb.StrengthProgress
  alias Crohnjobs.Strength.StrengthProgress
  alias Crohnjobs.Repo
  alias Crohnjobs.Trainers
  alias Crohnjobs.CustomExercises
  alias Crohnjobs.CustomExercises.CustomExercise
  alias Crohnjobs.Exercise
  import Ecto.Query
    use CrohnjobsWeb, :live_view

    def mount(params, session, socket) do
      user = socket.assigns.current_user
      trainer=Trainers.get_trainer_byUserId(user.id)
      exercise_id = String.to_integer(params["exercise_id"])
      customParams = params["custom"]
      client_id= String.to_integer( params["id"])

      exercise = if customParams=="no" do
        Exercise.get_exercise!(exercise_id)
      else
        Repo.get_by(CustomExercise, %{id: exercise_id, trainer_id: trainer.id})

      end

      if exercise == nil do
        {:ok, socket|>put_flash(:error, "Invalid Id")|>redirect(to: "/")}

    else

      strengthProgress= Repo.all(from s in StrengthProgress, where: s.exercise_id == ^exercise.id)
      IO.inspect(strengthProgress)
      newExerciseForm = StrengthProgress.changeset(%StrengthProgress{},%{})|>to_form()

      {:ok, assign(socket, newExerciseForm: newExerciseForm, client_id: client_id,   showModal: false, show_edit_exercise: false, exercise: exercise, strengthProgress: strengthProgress)}

    end
    end


    def handle_event("deleteProgress", params, socket) do
     client_id = socket.assigns.client_id
     id = String.to_integer( params["id"])
     strengthProgress = Strength.get_strength_progress!(id)
     case Strength.delete_strength_progress(strengthProgress) do
      {:ok, strengthProgress}->
        updatedStrength= Enum.reject(socket.assigns.strengthProgress, &(&1.id == id))
        {:noreply, assign(socket,strengthProgress: updatedStrength)}
     _ -> {:noreply,socket}

    end
  end


    def handle_event("openModal", _params, socket) do
      showModal = !socket.assigns.showModal
      {:noreply, assign(socket, showModal: showModal)}


    end


    def handle_event("saveProgress", params, socket) do
     client = socket.assigns.client_id
     date =
      case Date.from_iso8601(params["strength_progress"]["date"]) do
        {:ok, d} -> d
        _ -> nil
      end
         repRange = params["strength_progress"]["repRange"]
     weight = String.to_integer(params["strength_progress"]["weight"])
     case Strength.create_strength_progress(%{date: date, weight: weight, repRange: repRange, client_id: client, exercise_id: socket.assigns.exercise.id }) do
       {:ok, strength}->
        IO.inspect(strength)
        strengthProgress = socket.assigns.strengthProgress ++[strength]
        {:noreply, socket|> assign(showModal: false, strengthProgress: strengthProgress)}

     _ ->{:noreply, socket|> put_flash(:error, "An error has been occured")}
    end
  end


    def render(assigns) do
      ~H"""
      <div class="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100 py-8 px-4 sm:px-6 lg:px-8">
        <div class="max-w-6xl mx-auto">
          <!-- Header Section -->
          <div class="bg-white rounded-2xl shadow-lg p-8 mb-6">
            <div class="flex items-center justify-between">
              <div>
                <h1 class="text-4xl font-bold text-gray-900 mb-2">
                  {@exercise.name}
                </h1>
                <p class="text-gray-600">Track your strength progress over time</p>
              </div>
              <button
                phx-click="openModal"
                class="bg-gradient-to-r from-emerald-600 to-emerald-700 hover:from-emerald-700 hover:to-emerald-800 text-white font-semibold px-6 py-3 rounded-xl shadow-md hover:shadow-lg transition-all flex items-center gap-2">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                  <path fill-rule="evenodd" d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z" clip-rule="evenodd" />
                </svg>
                Add Progress
              </button>
            </div>
          </div>

          <!-- Modal -->
          <%= if @showModal do %>
            <div class="fixed inset-0 bg-black bg-opacity-60 flex items-center justify-center z-50 p-4 backdrop-blur-sm">
              <div class="bg-white rounded-2xl shadow-2xl w-full max-w-md transform transition-all">
                <div class="p-6 border-b border-gray-200">
                  <h2 class="text-2xl font-bold text-gray-900">Add New Progress</h2>
                  <p class="text-gray-600 text-sm mt-1">Record your latest workout performance</p>
                </div>

                <.form phx-submit="saveProgress" for={@newExerciseForm}>
                  <div class="p-6 space-y-5">
                    <div>
                      <label class="block text-sm font-semibold text-gray-700 mb-2">Date</label>
                      <.input
                        required
                        type="date"
                        field={@newExerciseForm[:date]}
                        class="w-full px-4 py-3 rounded-lg border border-gray-300 focus:ring-2 focus:ring-emerald-500 focus:border-transparent transition-all"
                      />
                    </div>

                    <div>
                      <label class="block text-sm font-semibold text-gray-700 mb-2">Rep Range</label>
                      <.input
                        type="select"
                        options={["3-5","5-8","8-10", "10-12","12-14","15+"]}
                        required
                        field={@newExerciseForm[:repRange]}
                        class="w-full px-4 py-3 rounded-lg border border-gray-300 focus:ring-2 focus:ring-emerald-500 focus:border-transparent transition-all"
                      />
                    </div>

                    <div>
                      <label class="block text-sm font-semibold text-gray-700 mb-2">Weight</label>
                      <.input
                        type="number"
                        field={@newExerciseForm[:weight]}
                        class="w-full px-4 py-3 rounded-lg border border-gray-300 focus:ring-2 focus:ring-emerald-500 focus:border-transparent transition-all"
                      />
                    </div>
                  </div>

                  <div class="p-6 bg-gray-50 rounded-b-2xl flex gap-3">
                    <button
                      type="button"
                      phx-click="openModal"
                      class="flex-1 bg-white border-2 border-gray-300 text-gray-700 font-semibold px-6 py-3 rounded-xl hover:bg-gray-50 transition-all duration-200">
                      Cancel
                    </button>
                    <.button class="flex-1 bg-gradient-to-r from-emerald-600 to-emerald-700 hover:from-emerald-700 hover:to-emerald-800 text-white font-semibold px-6 py-3 rounded-xl shadow-md hover:shadow-lg transition-all duration-200">
                      Save Progress
                    </.button>
                  </div>
                </.form>
              </div>
            </div>
          <% end %>

          <!-- Progress Table/Empty State -->
          <%= if length(@strengthProgress) > 0 do %>
            <div class="bg-white rounded-2xl shadow-lg overflow-hidden">
              <div class="overflow-x-auto">
                <table class="w-full">
                  <thead class="bg-gradient-to-r from-gray-50 to-gray-100">
                    <tr>
                      <th class="text-left py-5 px-6 font-bold text-gray-900 text-sm uppercase tracking-wider">Date</th>
                      <th class="text-left py-5 px-6 font-bold text-gray-900 text-sm uppercase tracking-wider">Rep Range</th>
                      <th class="text-left py-5 px-6 font-bold text-gray-900 text-sm uppercase tracking-wider">Weight</th>
                      <th class="text-right py-5 px-6 font-bold text-gray-900 text-sm uppercase tracking-wider">Actions</th>
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-gray-200">
                    <%= for strength <- @strengthProgress do %>
                      <tr class="hover:bg-gray-50 transition-colors duration-150">
                        <td class="py-5 px-6">
                          <div class="flex items-center gap-3">
                            <div class="w-10 h-10 bg-gradient-to-br from-emerald-100 to-emerald-200 rounded-lg flex items-center justify-center">
                              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-emerald-700" viewBox="0 0 20 20" fill="currentColor">
                                <path fill-rule="evenodd" d="M6 2a1 1 0 00-1 1v1H4a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V6a2 2 0 00-2-2h-1V3a1 1 0 10-2 0v1H7V3a1 1 0 00-1-1zm0 5a1 1 0 000 2h8a1 1 0 100-2H6z" clip-rule="evenodd" />
                              </svg>
                            </div>
                            <span class="font-semibold text-gray-900"><%= strength.date %></span>
                          </div>
                        </td>
                        <td class="py-5 px-6">
                          <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-semibold bg-blue-100 text-blue-800">
                            <%= strength.repRange %> reps
                          </span>
                        </td>
                        <td class="py-5 px-6">
                          <span class="text-lg font-bold text-gray-900"><%= strength.weight %></span>
                          <span class="text-sm text-gray-500 ml-1">KG</span>
                        </td>
                        <td class="py-5 px-6 text-right">
                          <.button
                            phx-value-id={strength.id}
                            phx-click="deleteProgress"
                            class="bg-red-50 hover:bg-red-100 text-red-700 font-semibold px-4 py-2 rounded-lg transition-all duration-200 border border-red-200">
                            Delete
                          </.button>
                        </td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>
            </div>
          <% else %>
            <div class="bg-white rounded-2xl shadow-lg p-12 text-center">
              <div class="w-20 h-20 bg-gradient-to-br from-gray-100 to-gray-200 rounded-full flex items-center justify-center mx-auto mb-6">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-10 w-10 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                </svg>
              </div>
              <h3 class="text-2xl font-bold text-gray-900 mb-2">No Progress Data Yet</h3>
              <p class="text-gray-600 mb-6">Start tracking your strength progress by adding your first workout entry.</p>
              <button
                phx-click="openModal"
                class="inline-flex items-center gap-2 bg-gradient-to-r from-emerald-600 to-emerald-700 hover:from-emerald-700 hover:to-emerald-800 text-white font-semibold px-6 py-3 rounded-xl shadow-md hover:shadow-lg transition-all duration-200">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                  <path fill-rule="evenodd" d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z" clip-rule="evenodd" />
                </svg>
                Add Your First Entry
              </button>
            </div>
          <% end %>
        </div>
      </div>
      """
    end
  end
