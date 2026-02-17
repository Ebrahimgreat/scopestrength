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
    <div class="w-full">
      <!-- Header -->
      <div class="mb-6">
        <h1 class="text-2xl font-semibold text-slate-900">Clients</h1>
        <p class="text-sm text-slate-600 mt-1"><%= length(@clients) %> total</p>
      </div>

      <!-- Table -->
      <%= if @clients == [] do %>
        <div class="text-center py-16 bg-slate-50/50 rounded-lg border border-slate-200">
          <div class="inline-flex items-center justify-center w-12 h-12 rounded-full bg-slate-100 mb-3">
            <svg class="w-6 h-6 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"></path>
            </svg>
          </div>
          <h3 class="text-base font-medium text-slate-900 mb-1">No clients yet</h3>
          <p class="text-sm text-slate-500">Add your first client to get started</p>
        </div>
      <% else %>
        <div class="bg-white border border-slate-200 rounded-lg overflow-hidden overflow-x-auto">
          <table class="w-full min-w-[500px]">
            <thead class="bg-slate-50 border-b border-slate-200">
              <tr>
                <th class="text-left px-4 sm:px-6 py-3 text-xs font-medium text-slate-600 uppercase tracking-wider">
                  Client
                </th>
                <th class="text-left px-4 sm:px-6 py-3 text-xs font-medium text-slate-600 uppercase tracking-wider hidden sm:table-cell">
                  Email
                </th>
                <th class="text-left px-4 sm:px-6 py-3 text-xs font-medium text-slate-600 uppercase tracking-wider">
                  Status
                </th>

              </tr>
            </thead>
            <tbody class="divide-y divide-slate-200">
              <%= for client <- @clients do %>

                <tr   phx-click={JS.navigate(~p"/trainer/clients/#{client.id}")}
                class="hover:bg-slate-50 transition-colors cursor-pointer">
                  <td class="px-4 sm:px-6 py-4">
                    <div class="flex items-center gap-3">
                      <%= if client.profile_picture_url do %>
                        <img src={client.profile_picture_url} alt={client.user.name} class="w-10 h-10 rounded-full object-cover border-2 border-slate-200 flex-shrink-0" />
                      <% else %>
                        <div class="w-10 h-10 bg-gradient-to-br from-emerald-400 to-emerald-600 rounded-full flex items-center justify-center flex-shrink-0">
                          <span class="text-white font-medium text-sm"><%= String.first(client.user.name || "?") |> String.upcase() %></span>
                        </div>
                      <% end %>
                      <div>
                        <div class="text-sm font-medium text-slate-900"><%= client.user.name %></div>
                        <div class="text-xs text-slate-500 sm:hidden"><%= client.user.email %></div>
                      </div>
                    </div>
                  </td>
                  <td class="px-4 sm:px-6 py-4 hidden sm:table-cell">
                    <div class="text-sm text-slate-600"><%= client.user.email %></div>
                  </td>
                  <td class="px-4 sm:px-6 py-4">
                    <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-emerald-100 text-emerald-700">
                      <div class="w-1.5 h-1.5 rounded-full bg-emerald-500"></div>
                      Active
                    </span>
                  </td>

                </tr>

              <% end %>
            </tbody>
          </table>
        </div>
      <% end %>
    </div>
    """
  end
end
