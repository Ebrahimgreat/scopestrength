defmodule CrohnjobsWeb.Clients do
  use CrohnjobsWeb, :live_view
  alias Crohnjobs.Trainers
  alias Crohnjobs.Clients

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    trainer = Trainers.get_trainer_byUserId(user.id)
    clients = Clients.get_clients_for_trainer(trainer.id)
    {:ok, assign(socket, clients: clients, trainer_id: trainer.id)}
  end



  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-zinc-50">
      <!-- Header Section -->
      <div class="bg-white shadow-lg border-b border-gray-100">
        <div class="w-full px-6 lg:px-10 py-8">
          <div class="flex items-center justify-between">
            <div class="flex items-center space-x-4">
              <div class="p-3 bg-gradient-to-r from-blue-500 to-indigo-600 rounded-xl shadow-lg">
                <svg class="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z"></path>
                </svg>
              </div>
              <div>
                <h1 class="text-3xl font-bold text-gray-900">My Clients</h1>
                <p class="text-gray-600 mt-1">Manage and track your client relationships</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Stats Section -->
      <div class="w-full px-6 lg:px-10 py-8">
        <div class="mb-8">
          <div class="bg-white rounded-2xl shadow-lg p-6 border border-gray-100 hover:shadow-xl transition-shadow duration-300 max-w-sm">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-medium text-gray-600 uppercase tracking-wider">Total Clients</p>
                <p class="text-3xl font-bold text-gray-900 mt-2"><%= length(@clients) %></p>
              </div>
              <div class="p-3 bg-blue-100 rounded-full">
                <svg class="w-8 h-8 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"></path>
                </svg>
              </div>
            </div>
          </div>
        </div>

        <!-- Client List -->
        <%= if @clients == [] do %>
          <div class="text-center py-16">
            <div class="mx-auto w-24 h-24 bg-gray-100 rounded-full flex items-center justify-center mb-6">
              <svg class="w-12 h-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"></path>
              </svg>
            </div>
            <h3 class="text-xl font-semibold text-gray-900 mb-2">No clients yet</h3>
            <p class="text-gray-600 max-w-md mx-auto">Clients will appear here once they register and are assigned to you.</p>
          </div>
        <% else %>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <%= for client <- @clients do %>
              <div class="group bg-white rounded-2xl shadow-lg hover:shadow-2xl transition-all duration-300 transform hover:-translate-y-1 border border-gray-100 overflow-hidden">
                <div class="p-6">
                  <div class="flex items-center space-x-4 mb-6">
                    <div class="w-16 h-16 bg-gradient-to-r from-blue-400 to-purple-500 rounded-full flex items-center justify-center shadow-lg">
                      <span class="text-white font-bold text-xl"><%= String.first(client.user.name || "?") |> String.upcase() %></span>
                    </div>
                    <div>
                      <h3 class="text-xl font-bold text-gray-900 group-hover:text-blue-600 transition-colors duration-200"><%= client.user.name %></h3>
                    </div>
                  </div>

                  <!-- Action Buttons -->
                  <div class="flex space-x-3">
                    <.link
                      navigate={~p"/trainer/clients/#{client.id}"}
                      class="flex-1 bg-gradient-to-r from-blue-500 to-indigo-600 hover:from-blue-600 hover:to-indigo-700 text-white text-center py-3 px-4 rounded-xl font-semibold transition-all duration-200 shadow-lg hover:shadow-xl transform hover:-translate-y-0.5 text-sm"
                    >
                      <div class="flex items-center justify-center space-x-2">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path>
                        </svg>
                        <span>View Profile</span>
                      </div>
                    </.link>

                  </div>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
