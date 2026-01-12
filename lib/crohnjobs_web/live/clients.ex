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

  def handle_event("addClient", params, socket) do
    newClient = %{name: "client", age: 18, notes: "None", active: true, sex: "male", height: 167, trainer_id: socket.assigns.trainer_id}
    case Clients.create_client(newClient) do
      {:ok, client} ->
        updatedClients = [client | socket.assigns.clients]
        {:noreply, assign(socket, clients: updatedClients)}
      _ -> {:noreply, socket |> put_flash(:error, "Error has occured")}
    end
  end

  def handle_event("removeClient", params, socket) do
    clients = socket.assigns.clients
    id = String.to_integer(params["id"])
    client = Clients.get_client!(id)
    case Clients.delete_client(client) do
      {:ok, _client} ->
        updatedClient = Enum.reject(clients, fn x -> x.id == id end)
        {:noreply, socket |> put_flash(:info, "Client Successfully Deleted") |> assign(clients: updatedClient)}
      _ -> {:noreply, socket |> put_flash(:error, "Something Happened")}
    end
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

            <.button
              phx-click="addClient"
              class="bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white px-6 py-3 rounded-xl shadow-lg hover:shadow-xl transform hover:-translate-y-0.5 transition-all duration-200 flex items-center space-x-2 font-semibold"
            >
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
              </svg>
              <span>Add New Client</span>
            </.button>
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
            <p class="text-gray-600 mb-8 max-w-md mx-auto">Get started by adding your first client. You can track their progress, manage sessions, and build lasting relationships.</p>
            <.button
              phx-click="addClient"
              class="bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white px-8 py-3 rounded-xl shadow-lg hover:shadow-xl transform hover:-translate-y-0.5 transition-all duration-200 font-semibold"
            >
              Add Your First Client
            </.button>
          </div>
        <% else %>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <%= for client <- @clients do %>
              <div class="group bg-white rounded-2xl shadow-lg hover:shadow-2xl transition-all duration-300 transform hover:-translate-y-1 border border-gray-100 overflow-hidden">
                <div class="p-6">
                  <div class="flex items-center space-x-4 mb-6">
                    <div class="w-16 h-16 bg-gradient-to-r from-blue-400 to-purple-500 rounded-full flex items-center justify-center shadow-lg">
                      <span class="text-white font-bold text-xl"><%= String.first(client.name) |> String.upcase() %></span>
                    </div>
                    <div>
                      <h3 class="text-xl font-bold text-gray-900 group-hover:text-blue-600 transition-colors duration-200"><%= client.name %></h3>
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

                    <.button
                      phx-value-id={client.id}
                      phx-click="removeClient"
                      data-confirm="Are you sure you want to delete this client? This action cannot be undone."
                      class="bg-red-500 hover:bg-red-600 text-white p-3 rounded-xl transition-all duration-200 shadow-lg hover:shadow-xl transform hover:-translate-y-0.5"
                    >
                      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                      </svg>
                    </.button>
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
