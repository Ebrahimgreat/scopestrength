defmodule CrohnjobsWeb.Dashboard do
  alias Crohnjobs.Repo
  alias Crohnjobs.Clients.Client
  use CrohnjobsWeb, :live_view
  alias Crohnjobs.Clients
  alias Crohnjobs.Trainers.Trainer
  alias Crohnjobs.Trainers


  def handle_event("updateStatus", params, socket) do


   newClient = Clients.get_client!(params["id"])
   status = newClient.active
   Clients.update_client(newClient,%{active: !status})

  {:noreply, assign(socket, clients: Clients.list_clients)}

  end
  def mount(_params, _session, socket) do


    user = socket.assigns.current_user

    trainers = Trainers.get_trainer_byUserId(user.id)
    data= Repo.get(Trainer, trainers.id)|>Repo.preload([:programmes,:clients])

    {:ok, assign(socket, name: user.name, data: data )}
  end

  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""

  <div class="w-full min-h-screen bg-zinc-50">
    <!-- Header -->
    <div class="w-full bg-gradient-to-r from-blue-600 to-purple-700 text-white px-6 lg:px-10 py-8">
      <h1 class="text-3xl font-bold tracking-tight">Trainer Dashboard</h1>
      <p class="mt-2 text-blue-100 text-lg">
        Welcome back, <span class="font-semibold"><%= @name %></span>! How is it going?
      </p>
    </div>

    <!-- Main Content -->
    <div class="w-full px-6 lg:px-10 py-8">


      <div class="grid grid-cols-1 sm:grid-cols-2 gap-6 mb-8">
        <div class="bg-white rounded-2xl p-6 shadow ring-1 ring-black/5 flex items-center gap-4">
          <div class="p-3 rounded-lg bg-gradient-to-r from-blue-500 to-purple-600 text-white flex items-center justify-center">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z"></path>
            </svg>
          </div>
          <div class="ml-4 flex-1">
            <h3 class="text-sm font-medium text-zinc-500 uppercase tracking-wide">Total Clients</h3>
            <p class="text-3xl font-bold text-zinc-900"><%= length(@data.clients) %></p>
          </div>
        </div>

        <div class="bg-white rounded-2xl p-6 shadow ring-1 ring-black/5 flex items-center gap-4">
          <div class="p-3 rounded-lg bg-gradient-to-r from-green-400 to-emerald-500 text-white flex items-center justify-center">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h4l3 8 4-16 3 8h4"></path>
            </svg>
          </div>
          <div class="ml-4 flex-1">
            <h3 class="text-sm font-medium text-zinc-500 uppercase tracking-wide">Programmes</h3>
            <p class="text-3xl font-bold text-zinc-900"><%= length(@data.programmes) %></p>
          </div>
        </div>
      </div>


      <%= if length(@data.programmes) > 0 do %>
        <div class="bg-white rounded-xl shadow-sm border border-gray-200 mb-8 overflow-hidden">
          <div class="px-6 py-4 border-b border-gray-200 bg-gray-50">
            <h2 class="text-lg font-semibold text-gray-900 flex items-center">
              <svg class="w-5 h-5 mr-2 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z"></path>
              </svg>
              Your Programmes
            </h2>
          </div>

          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Name</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Description</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500">View</th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <%= for programme <-@data.programmes do %>
                <tr class="hover:bg-gray-50 transition-colors duration-150">
                  <td class="px-6 py-4 whitespace-nowrap">
                    <div class="flex items-center">
                      <div class="flex-shrink-0 h-10 w-10 rounded-full bg-gradient-to-r from-blue-500 to-purple-600 flex items-center justify-center">
                        <span class="text-sm font-medium text-white"><%= String.first(programme.name) %></span>
                      </div>
                      <div class="ml-4">
                        <div class="text-sm font-medium text-gray-900"><%= programme.name %></div>
                      </div>
                    </div>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900"><%= programme.description %></td>
                  <td>
                    <.link navigate={~p"/programmes/#{programme.id}"}>
                      <.button>View</.button>
                    </.link>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      <% end %>

      <!-- Clients Table -->
      <%= if length(@data.clients) > 0 do %>
        <div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
          <div class="px-6 py-4 border-b border-gray-200 bg-gray-50">
            <h2 class="text-lg font-semibold text-gray-900 flex items-center">
              <svg class="w-5 h-5 mr-2 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z"></path>
              </svg>
              Your Clients
            </h2>
          </div>

          <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200">
              <thead class="bg-gray-50">
                <tr>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Name</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Age</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Active</th>
                  <th>View</th>
                </tr>
              </thead>
              <tbody class="bg-white divide-y divide-gray-200">
                <%= for client <- @data.clients do %>
                  <tr class="hover:bg-gray-50 transition-colors duration-150">
                    <td class="px-6 py-4 whitespace-nowrap">
                      <div class="flex items-center">
                        <div class="flex-shrink-0 h-10 w-10 rounded-full bg-gradient-to-r from-blue-500 to-purple-600 flex items-center justify-center">
                          <span class="text-sm font-medium text-white"><%= String.first(client.name) %></span>
                        </div>
                        <div class="ml-4">
                          <div class="text-sm font-medium text-gray-900"><%= client.name %></div>
                        </div>
                      </div>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      <%= if client.age, do: "#{client.age} years", else: "<span class='text-gray-400'>Not specified</span>" %>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap">
                      <%= if client.active do %>
                        <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
                          Active
                        </span>
                      <% else %>
                        <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-red-100 text-red-800">
                          Inactive
                        </span>
                      <% end %>
                    </td>
                    <td>
                      <.link navigate={~p"/clients/#{client.id}"}>
                        <.button>View</.button>
                      </.link>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </div>
      <% else %>
        <div class="text-center py-12">
          <h3 class="mt-4 text-lg font-medium text-gray-900">No clients yet</h3>
          <p class="mt-2 text-gray-500">Get started by adding your first client to begin training sessions.</p>
        </div>
      <% end %>

    </div>
  </div>
  """
end

end
