defmodule CrohnjobsWeb.ShowClient do
  alias Phoenix.LiveViewTest.View
  alias Crohnjobs.Programmes.Programme
  alias Crohnjobs.Clients
  alias Crohnjobs.Clients.Client
  alias Crohnjobs.Repo
  alias Crohnjobs.Account
  alias Crohnjobs.Programmes.ProgrammeUser
  use CrohnjobsWeb, :live_view
  import Ecto.Query

  def handle_event("updateClient", params, socket) do
    client = socket.assigns.client.data
    name = params["client"]["name"]
    age =  String.to_integer(params["client"]["age"])
    height = String.to_integer(params["client"]["height"])
    sex = params["client"]["sex"]
    notes = params["client"]["notes"]
    case Clients.update_client(client, %{name: name, age: age, sex: sex, height: height, notes: notes }) do
      {:ok, client}->
        client = Clients.change_client(client)|> to_form()
        {:noreply,  socket|> put_flash(:info, "Client Updated")|> assign(client: client)}
        _ -> {:noreply, socket|> put_flash(:error, "Something Happened")}

    end

  end

  def mount(params, session, socket) do
  client = Repo.get!(Client,params["id"])

  programmeUser = Repo.get_by(ProgrammeUser, client_id: client.id, is_active: true)|> Repo.preload(:programme)
 programmes =  case programmeUser do
    nil -> nil
    pu  -> pu
  end
  IO.inspect(programmes)

  clientForm = Clients.change_client(client)|>to_form()

  {:ok, assign(socket, programmeUser: programmes,  client: clientForm)}


  end
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-purple-50 to-blue-100 py-8">
      <div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
        <!-- Header Section -->
        <div class="mb-8">
          <div class="bg-white rounded-xl shadow-lg border-2 border-purple-200 p-8">
            <div class="flex items-center justify-between">
              <div class="flex items-center space-x-6">
                <div class="w-20 h-20 bg-purple-600 rounded-full flex items-center justify-center shadow-lg">
                  <span class="text-3xl font-bold text-white">
                    <%= String.first(@client.data.name || "C") |> String.upcase() %>
                  </span>
                </div>
                <div>
                  <h1 class="text-4xl font-bold text-gray-900"><%= @client.data.name || "Client" %></h1>
                  <p class="text-lg text-gray-600 mt-1">Client Profile & Management</p>
                </div>
              </div>
              <div class="text-right">
                <.link
                  navigate={~p"/clients"}
                  class="inline-flex items-center px-4 py-2 bg-gray-600 hover:bg-gray-700 text-white font-semibold rounded-lg shadow-md transition-all duration-200"
                >
                  <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
                  </svg>
                  Back to Clients
                </.link>
              </div>
            </div>
          </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
          <!-- Client Information Form -->
          <div class="bg-white rounded-xl shadow-lg border-2 border-blue-200">
            <div class="bg-blue-600 px-6 py-4 rounded-t-xl">
              <h2 class="text-xl font-bold text-white flex items-center">
                <svg class="w-6 h-6 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                </svg>
                Client Information
              </h2>
              <p class="text-blue-100 mt-1">Update client details and personal information</p>
            </div>

            <div class="p-6">
              <.form phx-submit="updateClient" for={@client} class="space-y-6">
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div class="bg-green-50 p-4 rounded-lg border-2 border-green-200">
                    <label class="block text-sm font-bold text-green-700 mb-2">Full Name</label>
                    <.input
                      field={@client[:name]}
                      class="w-full px-3 py-2 text-lg font-semibold border-2 border-green-300 rounded-lg focus:border-green-500 focus:ring-2 focus:ring-green-200 bg-white"
                      placeholder="Enter client's full name"
                    />
                  </div>

                  <div class="bg-orange-50 p-4 rounded-lg border-2 border-orange-200">
                    <label class="block text-sm font-bold text-orange-700 mb-2">Age</label>
                    <.input
                      field={@client[:age]}
                      type="number"
                      min="1"
                      max="120"
                      class="w-full px-3 py-2 text-lg font-semibold border-2 border-orange-300 rounded-lg focus:border-orange-500 focus:ring-2 focus:ring-orange-200 bg-white"
                    />
                  </div>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div class="bg-purple-50 p-4 rounded-lg border-2 border-purple-200">
                    <label class="block text-sm font-bold text-purple-700 mb-2">Height (cm)</label>
                    <.input
                      field={@client[:height]}
                      type="number"
                      min="1"
                      max="300"
                      class="w-full px-3 py-2 text-lg font-semibold border-2 border-purple-300 rounded-lg focus:border-purple-500 focus:ring-2 focus:ring-purple-200 bg-white"
                    />
                  </div>

                  <div class="bg-pink-50 p-4 rounded-lg border-2 border-pink-200">
                    <label class="block text-sm font-bold text-pink-700 mb-2">Gender</label>
                    <.input type="select"
                    options={[{"Male", "male"}, {"Female", "female"}, {"Other", "other"}]}
                    field={@client[:sex]}
                      class="w-full px-3 py-2 text-lg font-semibold border-2 border-pink-300 rounded-lg focus:border-pink-500 focus:ring-2 focus:ring-pink-200 bg-white"
                    />
                  </div>
                </div>

                <div class="bg-indigo-50 p-4 rounded-lg border-2 border-indigo-200">
                  <label class="block text-sm font-bold text-indigo-700 mb-2">Notes</label>
                  <.input
                    field={@client[:notes]}
                    type="textarea"
                    rows="4"
                    class="w-full px-3 py-2 text-lg border-2 border-indigo-300 rounded-lg focus:border-indigo-500 focus:ring-2 focus:ring-indigo-200 bg-white"
                    placeholder="Add any additional notes about the client..."
                  />
                </div>

                <div class="flex justify-end">
                  <.button class="bg-green-600 hover:bg-green-700 text-white px-8 py-3 rounded-lg font-bold text-lg shadow-lg transition-all duration-200 transform hover:scale-105">
                    <svg class="w-5 h-5 mr-2 inline" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12" />
                    </svg>
                    Update Client
                  </.button>
                </div>
              </.form>
            </div>
          </div>

          <!-- Programme Information -->
          <div class="bg-white rounded-xl shadow-lg border-2 border-green-200">
            <div class="bg-green-600 px-6 py-4 rounded-t-xl">
              <h2 class="text-xl font-bold text-white flex items-center">
                <svg class="w-6 h-6 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
                Programme Enrollment
              </h2>
              <p class="text-green-100 mt-1">Current programme assignment and management</p>
            </div>

            <div class="p-6">
              <%= if @programmeUser != nil do %>
                <div class="bg-gradient-to-br from-blue-50 to-indigo-50 rounded-xl p-6 border-2 border-blue-200 mb-6">
                  <div class="flex items-center justify-between mb-4">
                    <div class="flex items-center space-x-3">
                      <div class="w-12 h-12 bg-blue-600 rounded-full flex items-center justify-center shadow-lg">
                        <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z" />
                        </svg>
                      </div>
                      <div>
                        <p class="text-sm font-semibold text-blue-600 uppercase tracking-wide">Currently Enrolled</p>
                        <h3 class="text-2xl font-bold text-gray-900"><%= @programmeUser.programme.name %></h3>
                      </div>
                    </div>
                    <div class="bg-green-500 text-white px-4 py-2 rounded-full shadow-md">
                      <span class="font-bold text-sm">ACTIVE</span>
                    </div>
                  </div>

                  <div class="flex justify-end">
                    <.link
                      navigate={~p"/programmes/#{@programmeUser.programme_id}"}
                      class="inline-flex items-center px-6 py-3 bg-indigo-600 hover:bg-indigo-700 text-white font-bold rounded-lg shadow-lg transition-all duration-200 transform hover:scale-105"
                    >
                      <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                      </svg>
                      View Programme Details
                    </.link>
                  </div>
                </div>
              <% else %>
                <div class="bg-gradient-to-br from-yellow-50 to-orange-50 rounded-xl p-8 border-2 border-yellow-200 text-center mb-6">
                  <div class="w-16 h-16 bg-yellow-400 rounded-full flex items-center justify-center mx-auto mb-4 shadow-lg">
                    <svg class="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.996-.833-2.768 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
                    </svg>
                  </div>
                  <h3 class="text-xl font-bold text-gray-900 mb-2">No Programme Assigned</h3>
                  <p class="text-gray-600">This client is not currently enrolled in any programme.</p>
                </div>
              <% end %>

              <!-- Change Programme Button -->
              <div class="bg-gray-50 rounded-xl p-4 border-2 border-gray-200">
                <div class="flex items-center justify-between">
                  <div>
                    <h4 class="font-bold text-gray-900">Programme Management</h4>
                    <p class="text-sm text-gray-600">Assign or change the client's programme</p>
                  </div>
                  <.link navigate={~p"/client/#{@client.data.id}/programme"}>
                    <.button class="bg-orange-600 hover:bg-orange-700 text-white px-6 py-3 rounded-lg font-bold shadow-lg transition-all duration-200 transform hover:scale-105">
                      <svg class="w-5 h-5 mr-2 inline" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4" />
                      </svg>
                      Change Programme
                    </.button>
                  </.link>

                </div>

              </div>
              <.link
    navigate={~p"/clients/#{@client.data.id}/workouts"}
    class="inline-flex items-center px-6 py-3 bg-green-600 hover:bg-green-700 text-white font-bold rounded-lg shadow-lg transition-all duration-200 transform hover:scale-105"
  >
    <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 17v-2h6v2m2 4H7a2 2 0 01-2-2V7a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
    </svg>
    View Workouts
  </.link>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

end
