defmodule CrohnjobsWeb.TrainerChat do
alias Crohnjobs.Clients.Client
alias Crohnjobs.Repo
alias Crohnjobs.Trainers
  use CrohnjobsWeb, :live_view
  import Ecto.Query


  def mount(_params, session, socket) do
    user = socket.assigns.current_user
    trainer = Trainers.get_trainer_byUserId(user.id)
    clients = Repo.all(from c in Client, where: c.trainer_id == ^trainer.id)
    {:ok, assign(socket, clients: clients)}



  end
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto p-4">
      <h1 class="text-2xl font-bold mb-6">Messages</h1>

      <%= if length(@clients) == 0 do %>
        <div class="text-center py-12">
          <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
          </svg>
          <h3 class="mt-4 text-lg font-medium text-gray-900">No clients yet</h3>
          <p class="mt-2 text-gray-500">Once you have clients, you can chat with them here.</p>
        </div>
      <% else %>
        <div class="bg-white rounded-lg shadow divide-y divide-gray-200">
          <%= for client <- @clients do %>
            <.link navigate={~p"/chat/#{client.id}"} class="block hover:bg-gray-50 transition-colors">
              <div class="flex items-center px-4 py-4">
                <div class="flex-shrink-0">
                  <div class="h-12 w-12 rounded-full bg-blue-500 flex items-center justify-center text-white font-semibold text-lg">
                    <%= String.first(client.name || "?") |> String.upcase() %>
                  </div>
                </div>
                <div class="ml-4 flex-1">
                  <div class="flex items-center justify-between">
                    <p class="text-sm font-medium text-gray-900"><%= client.name %></p>
                    <svg class="h-5 w-5 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                    </svg>
                  </div>
                  <p class="text-sm text-gray-500">Tap to start chatting</p>
                </div>
              </div>
            </.link>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

end
