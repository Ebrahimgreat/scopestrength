defmodule CrohnjobsWeb.Clients do
  use CrohnjobsWeb, :live_view
  alias Crohnjobs.Trainers
  alias Crohnjobs.Clients

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    trainer = Trainers.get_trainer_byUserId(user.id)
    clients = Clients.get_clients_for_trainer(trainer.id)

    {:ok, assign(socket, clients: clients)}
  end
  

  def render(assigns) do
    ~H"""
    <div class="p-8">
      <h1 class="text-2xl font-bold mb-4">My Clients</h1>

      <%= if @clients == [] do %>
        <p class="text-gray-600">No clients assigned yet.</p>
      <% else %>
        <ul class="space-y-2">
          <%= for client <- @clients do %>
            <li class="p-4 bg-white rounded shadow flex items-center justify-between">
              <div>
                <p class="font-semibold text-lg"><%= client.name %></p>
                <p class="text-sm text-gray-500">Age: <%= client.age %></p>
              </div>

              <.link
                navigate={~p"/clients/#{client.id}"}
                class="text-blue-600 hover:underline"
              >
                View Profile
              </.link>
              <.button>
              Delete client
              </.button>

            </li>
          <% end %>
        </ul>
      <% end %>
    </div>
    """
  end
end
