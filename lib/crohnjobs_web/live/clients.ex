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
    newClient = %{name: "client", age: 18, notes: "None", sex: "male", height: 167, trainer_id: socket.assigns.trainer_id}
    case Clients.create_client(newClient) do
      {:ok, client}->
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
     {:ok,_client}->
      updatedClient= Enum.reject(clients, fn x-> x.id == id end)
      {:noreply, socket|> put_flash(:info, "Client Sucessfully Deleted")|>assign(clients: updatedClient)}

      _ -> {:noreply, socket|> put_flash(:error, "Something Happened")}
   end


  end
  def render(assigns) do
    ~H"""
    <div class="p-8">
    <.button phx-click="addClient">
    Add Client
    </.button>
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
              <.button phx-value-id={client.id} phx-click="removeClient">
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
