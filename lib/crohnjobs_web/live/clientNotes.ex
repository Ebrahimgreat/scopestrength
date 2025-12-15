defmodule CrohnjobsWeb.ClientNotes do
  import Ecto.Query
  alias Crohnjobs.ClientNote
  alias Crohnjobs.ClientNote.ClientNotes
  alias Crohnjobs.Repo
    use CrohnjobsWeb, :live_view

    def mount(params, session, socket) do
      client_id = String.to_integer(params["id"])
      clientNote= ClientNotes.changeset(%ClientNotes{}, %{})|>to_form()
      notes = Repo.all(from c in ClientNotes, where: c.client_id == ^client_id)
      {:ok, assign(socket, client_id: client_id, notes: notes, showModal: false, newForm: clientNote )}

    end

    def handle_event("openModal", _params, socket) do
      showModal = !socket.assigns.showModal
      {:noreply, assign(socket, showModal: showModal)}


    end

    def handle_event("deleteNote", params, socket) do
      id = String.to_integer(params["id"])
      notes = ClientNote.get_client_notes!(id)
      case ClientNote.delete_client_notes(notes) do
        {:ok, _notes}->
          updatedNotes = Enum.reject(socket.assigns.notes, &(&1.id== id))
          {:noreply,assign(socket, notes: updatedNotes)}
          _ ->{:noreply,socket|>put_flash(:error, "An error has occured")}
      end

    end


    def handle_event("addNote", params, socket) do
      notes = params["client_notes"]["notes"]
      date =
        case Date.from_iso8601(params["client_notes"]["date"]) do
        {:ok, d} -> d
        _ -> nil
      end
      case ClientNote.create_client_notes(%{date: date, notes: notes, client_id: socket.assigns.client_id}) do
        {:ok, notes}->
          notes = socket.assigns.notes++[notes]
          {:noreply, socket|>assign(showModal: false, notes: notes)}

      _ ->{:noreply, socket|>put_flash(:error, "An error has occured")}
        end
    end
    def render(assigns) do
      ~H"""
      <div class="min-h-screen bg-gradient-to-br from-indigo-50 via-purple-50 to-pink-50 py-8 px-4 sm:px-6 lg:px-8">
        <div class="max-w-7xl mx-auto">
        
          <div class="bg-white rounded-2xl shadow-xl p-8 mb-6 border border-purple-100">
            <div class="flex items-center justify-between">
              <div>
                <h1 class="text-4xl font-bold bg-gradient-to-r from-purple-600 to-pink-600 bg-clip-text text-transparent mb-2">
                  Client Notes
                </h1>
                <p class="text-gray-600">Keep track of important client observations and progress notes</p>
              </div>
              <button
                phx-click="openModal"
                class="bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700 text-white font-semibold px-6 py-3 rounded-xl shadow-lg hover:shadow-xl transition-all duration-200 flex items-center gap-2">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                  <path d="M13.586 3.586a2 2 0 112.828 2.828l-.793.793-2.828-2.828.793-.793zM11.379 5.793L3 14.172V17h2.828l8.38-8.379-2.83-2.828z" />
                </svg>
                Add Note
              </button>
            </div>
          </div>


          <%= if @showModal do %>
            <div class="fixed inset-0 bg-black bg-opacity-60 flex items-center justify-center z-50 p-4 backdrop-blur-sm">
              <div class="bg-white rounded-2xl shadow-2xl w-full max-w-2xl transform transition-all">
                <div class="p-6 border-b border-gray-200 bg-gradient-to-r from-purple-50 to-pink-50">
                  <h2 class="text-2xl font-bold text-gray-900">Add New Note</h2>
                  <p class="text-gray-600 text-sm mt-1">Document important client information and observations</p>
                </div>

                <.form phx-submit="addNote" for={@newForm}>
                  <div class="p-6 space-y-5">
                    <div>
                      <label class="block text-sm font-semibold text-gray-700 mb-2">Date</label>
                      <.input
                        type="date"
                        required
                        field={@newForm[:date]}
                        class="w-full px-4 py-3 rounded-lg border border-gray-300 focus:ring-2 focus:ring-purple-500 focus:border-transparent transition-all"
                      />
                    </div>

                    <div>
                      <label class="block text-sm font-semibold text-gray-700 mb-2">Note</label>
                      <.input
                        type="text"
                        field={@newForm[:notes]}
                        class="w-full px-4 py-3 rounded-lg border border-gray-300 focus:ring-2 focus:ring-purple-500 focus:border-transparent transition-all"
                        placeholder="Enter your note here..."
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
                    <.button class="flex-1 bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700 text-white font-semibold px-6 py-3 rounded-xl shadow-md hover:shadow-lg transition-all duration-200">
                      Save Note
                    </.button>
                  </div>
                </.form>
              </div>
            </div>
          <% end %>

          <!-- Notes Display -->
          <%= if length(@notes) > 0 do %>
            <div class="grid gap-4">
              <%= for note <- @notes do %>
                <div class="bg-white rounded-xl shadow-md hover:shadow-lg transition-all duration-200 border border-purple-100 overflow-hidden">
                  <div class="p-6">
                    <div class="flex items-start justify-between gap-4">
                      <div class="flex-1">
                        <div class="flex items-center gap-3 mb-3">
                          <div class="w-12 h-12 bg-gradient-to-br from-purple-100 to-pink-100 rounded-xl flex items-center justify-center flex-shrink-0">
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-purple-600" viewBox="0 0 20 20" fill="currentColor">
                              <path fill-rule="evenodd" d="M6 2a1 1 0 00-1 1v1H4a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V6a2 2 0 00-2-2h-1V3a1 1 0 10-2 0v1H7V3a1 1 0 00-1-1zm0 5a1 1 0 000 2h8a1 1 0 100-2H6z" clip-rule="evenodd" />
                            </svg>
                          </div>
                          <div>
                            <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-purple-100 text-purple-800">
                              <%= note.date %>
                            </span>
                          </div>
                        </div>
                        <div class="bg-gradient-to-r from-purple-50 to-pink-50 rounded-lg p-4 border border-purple-100">
                          <p class="text-gray-800 leading-relaxed"><%= note.notes %></p>
                        </div>
                      </div>
                      <button
                        phx-click="deleteNote"
                        phx-value-id={note.id}
                        class="flex-shrink-0 bg-red-50 hover:bg-red-100 text-red-700 font-semibold px-4 py-2 rounded-lg transition-all duration-200 border border-red-200 flex items-center gap-2">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
                          <path fill-rule="evenodd" d="M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm5-1a1 1 0 00-1 1v6a1 1 0 102 0V8a1 1 0 00-1-1z" clip-rule="evenodd" />
                        </svg>
                        Delete
                      </button>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          <% else %>
            <div class="bg-white rounded-2xl shadow-lg p-12 text-center border border-purple-100">
              <div class="w-24 h-24 bg-gradient-to-br from-purple-100 to-pink-100 rounded-full flex items-center justify-center mx-auto mb-6">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-12 w-12 text-purple-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                </svg>
              </div>
              <h3 class="text-2xl font-bold text-gray-900 mb-2">No Notes Yet</h3>
              <p class="text-gray-600 mb-6">Start documenting important client information by adding your first note.</p>
              <button
                phx-click="openModal"
                class="inline-flex items-center gap-2 bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700 text-white font-semibold px-6 py-3 rounded-xl shadow-lg hover:shadow-xl transition-all duration-200">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                  <path d="M13.586 3.586a2 2 0 112.828 2.828l-.793.793-2.828-2.828.793-.793zM11.379 5.793L3 14.172V17h2.828l8.38-8.379-2.83-2.828z" />
                </svg>
                Add Your First Note
              </button>
            </div>
          <% end %>
        </div>
      </div>
      """
    end
  end
