defmodule CrohnjobsWeb.ShowClient do
  alias Crohnjobs.Trainers
  alias Crohnjobs.Clients.Client
  alias Crohnjobs.Repo
  alias Crohnjobs.Programmes.ProgrammeUser
  use CrohnjobsWeb, :live_view

  def mount(params, _session, socket) do
    user = socket.assigns.current_user
    trainer = Trainers.get_trainer_byUserId(user.id)

    id = String.to_integer(params["id"])
   case Repo.get(Client, id) |> Repo.preload(:user) do
    nil -> {:ok, socket |> put_flash(:error, "Client Not found") |> redirect(to: "/clients")}
    client ->
      case client.trainer_id == trainer.id do
        true ->
          programmeUser = Repo.get_by(ProgrammeUser, client_id: client.id, is_active: true) |> Repo.preload(:programme)

          {:ok, assign(socket, programmeUser: programmeUser, client: client)}


      false->{:ok, socket|> put_flash(:error, "Client Does not Exist")}
end
   end
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-purple-50 to-blue-100 py-8">
      <div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">

        <!-- Header Section -->
        <div class="mb-8">
          <div class="bg-white rounded-xl shadow-lg border-2 border-purple-200 p-8 flex justify-between items-center">
            <div class="flex items-center space-x-6">
              <div class="w-20 h-20 bg-purple-600 rounded-full flex items-center justify-center shadow-lg">
                <span class="text-3xl font-bold text-white">
                  <%= String.first(@client.user.name || "?") |> String.upcase() %>
                </span>
              </div>
              <div>
                <h1 class="text-4xl font-bold text-gray-900"><%= @client.user.name %></h1>
                <p class="text-lg text-gray-600 mt-1">Client Profile & Management</p>
              </div>
            </div>
            <.link
              navigate={~p"/trainer/clients"}
              class="inline-flex items-center px-4 py-2 bg-gray-600 hover:bg-gray-700 text-white font-semibold rounded-lg shadow-md transition-all duration-200"
            >
              <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
              </svg>
              Back to Clients
            </.link>
          </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">

          <!-- Client Information -->
          <div class="bg-white rounded-xl shadow-lg border-2 border-blue-200">
            <div class="bg-blue-600 px-6 py-4 rounded-t-xl">
              <h2 class="text-xl font-bold text-white flex items-center">
                <svg class="w-6 h-6 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                </svg>
                Client Information
              </h2>
              <p class="text-blue-100 mt-1">Client details and personal information</p>
            </div>

            <div class="p-6 space-y-4">
              <!-- Name & Age -->
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div class="bg-green-50 p-4 rounded-lg border-2 border-green-200">
                  <label class="block text-sm font-bold text-green-700 mb-2">Full Name</label>
                  <p class="text-lg font-semibold text-gray-900"><%= @client.user.name %></p>
                </div>
                <div class="bg-orange-50 p-4 rounded-lg border-2 border-orange-200">
                  <label class="block text-sm font-bold text-orange-700 mb-2">Age</label>
                  <p class="text-lg font-semibold text-gray-900"><%= @client.age || "Not specified" %></p>
                </div>
              </div>

              <!-- Height & Gender -->
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div class="bg-purple-50 p-4 rounded-lg border-2 border-purple-200">
                  <label class="block text-sm font-bold text-purple-700 mb-2">Height (cm)</label>
                  <p class="text-lg font-semibold text-gray-900"><%= @client.height || "Not specified" %></p>
                </div>
                <div class="bg-pink-50 p-4 rounded-lg border-2 border-pink-200">
                  <label class="block text-sm font-bold text-pink-700 mb-2">Gender</label>
                  <p class="text-lg font-semibold text-gray-900"><%= String.capitalize(@client.sex || "Not specified") %></p>
                </div>
              </div>

              <!-- Notes -->
              <div class="bg-indigo-50 p-4 rounded-lg border-2 border-indigo-200">
                <label class="block text-sm font-bold text-indigo-700 mb-2">Notes</label>
                <p class="text-lg text-gray-900"><%= @client.notes || "No notes" %></p>
              </div>
            </div>
          </div>

          <!-- Right Column: Programme, Strength, Notes -->
          <div class="space-y-6">

            <!-- Programme Section -->
            <div class="bg-white rounded-xl shadow-lg border-2 border-green-200">
              <div class="bg-green-600 px-6 py-4 rounded-t-xl">
                <h2 class="text-xl font-bold text-white flex items-center">
                  <svg class="w-6 h-6 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                  </svg>
                  Programme Enrollment
                </h2>
                <p class="text-green-100 mt-1">Current programme assignment</p>
              </div>

              <div class="p-6">
                <%= if @programmeUser != nil do %>
                  <div class="bg-gradient-to-br from-blue-50 to-indigo-50 rounded-xl p-6 border-2 border-blue-200 mb-4">
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
                      <.link navigate={~p"/trainer/programmes/#{@programmeUser.programme_id}"} class="inline-flex items-center px-6 py-3 bg-indigo-600 hover:bg-indigo-700 text-white font-bold rounded-lg shadow-lg transition-all duration-200 transform hover:scale-105">
                        View Programme Details
                      </.link>
                    </div>
                  </div>
                <% else %>
                  <div class="bg-gradient-to-br from-yellow-50 to-orange-50 rounded-xl p-8 border-2 border-yellow-200 text-center mb-4">
                    <h3 class="text-xl font-bold text-gray-900 mb-2">No Programme Assigned</h3>
                    <p class="text-gray-600">This client is not currently enrolled in any programme.</p>
                  </div>
                <% end %>

                <.link navigate={~p"/trainer/client/#{@client.id}/programme"}>
                  <.button class="bg-orange-600 hover:bg-orange-700 text-white px-6 py-3 rounded-lg font-bold shadow-lg transition-all duration-200 transform hover:scale-105 w-full">
                    Change Programme
                  </.button>
                </.link>
              </div>
            </div>

            <!-- Strength Progress Section -->
            <div class="bg-white rounded-xl shadow-lg border-2 border-gray-200">
              <div class="bg-gray-600 px-6 py-4 rounded-t-xl">
                <h2 class="text-xl font-bold text-white flex items-center">
                  Strength Progress
                </h2>
                <p class="text-gray-100 mt-1">Monitor the strength progress of the client</p>
              </div>
              <div class="p-6">
                <.link navigate={~p"/trainer/clients/#{@client.id}/strengthProgress"}>
                  <.button class="bg-orange-600 hover:bg-orange-700 text-white px-6 py-3 rounded-lg font-bold shadow-lg transition-all duration-200 transform hover:scale-105 w-full">
                    View Strength Progress
                  </.button>
                </.link>
              </div>
            </div>

            <!-- Notes Management Section -->
            <div class="bg-white rounded-xl shadow-lg border-2 border-gray-200">
              <div class="bg-indigo-600 px-6 py-4 rounded-t-xl">
                <h2 class="text-xl font-bold text-white flex items-center">
                  Notes Management
                </h2>
                <p class="text-indigo-100 mt-1">Add or review additional notes for the client</p>
              </div>
              <div class="p-6">
                <.link navigate={~p"/trainer/clients/#{@client.id}/notes"}>
                  <.button class="bg-orange-600 hover:bg-orange-700 text-white px-6 py-3 rounded-lg font-bold shadow-lg transition-all duration-200 transform hover:scale-105 w-full">
                    Manage Notes
                  </.button>
                </.link>
              </div>
            </div>

          </div>
        </div>
      </div>
    </div>
    """
  end
end
