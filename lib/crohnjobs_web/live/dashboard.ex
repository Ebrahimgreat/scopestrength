defmodule CrohnjobsWeb.Dashboard do
  alias Phoenix.LiveViewTest.View
  alias Crohnjobs.Clients.Client
  use CrohnjobsWeb, :live_view
  alias Crohnjobs.Clients
  alias Crohnjobs.Trainers


  def handle_event("updateStatus", params, socket) do
    IO.inspect(params)

   newClient = Clients.get_client!(5)
   status = newClient.active
   Clients.update_client(newClient,%{active: !status})
  {:noreply, assign(socket, clients: Clients.list_clients)}

  end
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    trainers = Trainers.get_trainer_byUserId(user.id)
    myClients = Clients.get_clients_for_trainer(trainers.id)
    {:ok, assign(socket, name: user.name, clients: myClients)}
  end

  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50">
      <!-- Header Section -->
      <div class="bg-gradient-to-r from-blue-600 to-purple-700 text-white">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <h1 class="text-3xl font-bold tracking-tight">Trainer Dashboard</h1>
          <p class="mt-2 text-blue-100 text-lg">
            Welcome back, <span class="font-semibold"><%= @name %></span>! How is it going?
          </p>
        </div>
      </div>

      <!-- Main Content -->
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <!-- Total Clients Card -->
        <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6 mb-8">
          <div class="flex items-center">
            <div class="flex-shrink-0">
              <div class="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
                <svg class="w-6 h-6 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z"></path>
                </svg>
              </div>
            </div>
            <div class="ml-4 flex-1">
              <h3 class="text-sm font-medium text-gray-500 uppercase tracking-wide">Total Number of Clients</h3>
              <p class="text-2xl font-bold text-gray-900"><%= length(@clients) %></p>
            </div>
          </div>
        </div>

        <!-- Clients Table -->
        <div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
          <div class="px-6 py-4 border-b border-gray-200 bg-gray-50">
            <h2 class="text-lg font-semibold text-gray-900 flex items-center">
              <svg class="w-5 h-5 mr-2 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z"></path>
              </svg>
              Your Clients
            </h2>
          </div>

          <%= if length(@clients) > 0 do %>
            <div class="overflow-x-auto">
              <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                  <tr>
                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Name
                    </th>
                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Age
                    </th>
                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Active
                    </th>
                    <th>
                    Action
                    </th>
                    <th>
                    View
                    </th>
                  </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                  <%= for client <- @clients do %>
                    <tr class="hover:bg-gray-50 transition-colors duration-150">
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div class="flex items-center">
                          <div class="flex-shrink-0 h-10 w-10">
                            <div class="h-10 w-10 rounded-full bg-gradient-to-r from-blue-500 to-purple-600 flex items-center justify-center">
                              <span class="text-sm font-medium text-white">
                                <%= String.first(client.user.name) %>
                              </span>
                            </div>
                          </div>
                          <div class="ml-4">
                            <div class="text-sm font-medium text-gray-900">
                              <%= client.user.name %>
                            </div>
                          </div>
                        </div>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div class="text-sm text-gray-900">
                          <%= if client.age do %>
                            <%= client.age %> years
                          <% else %>
                            <span class="text-gray-400">Not specified</span>
                          <% end %>
                        </div>
                      </td>


                      <td class="px-6 py-4 whitespace-nowrap">
                        <%= if client.active do %>
                          <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
                            <svg class="w-3 h-3 mr-1.5" fill="currentColor" viewBox="0 0 20 20">
                              <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"></path>
                            </svg>
                            Active
                          </span>
                        <% else %>
                          <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-red-100 text-red-800">
                            <svg class="w-3 h-3 mr-1.5" fill="currentColor" viewBox="0 0 20 20">
                              <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"></path>
                            </svg>
                            Inactive
                          </span>
                        <% end %>
                      </td>


                      <td class="px-6 py-4 whitespace-nowrap">
                      <.button  phx-click="updateStatus" phx-value-id={client.id}>
                      Change Status
                      </.button>
                      </td>
                      <td>
                      <.link  navigate={~p"/clients/#{client.id}"}>
                      View
                      </.link>

                      </td>

                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          <% else %>
            <!-- Empty State -->
            <div class="text-center py-12">
              <svg class="mx-auto h-16 w-16 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"></path>
              </svg>
              <h3 class="mt-4 text-lg font-medium text-gray-900">No clients yet</h3>
              <p class="mt-2 text-gray-500">Get started by adding your first client to begin training sessions.</p>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
