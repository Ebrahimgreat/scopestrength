defmodule CrohnjobsWeb.Clients do
  use CrohnjobsWeb, :live_view
  alias Crohnjobs.Trainers
  alias Crohnjobs.Clients

def mount(_params, session, socket) do
  user = socket.assigns.current_user
  trainer = Trainers.get_trainer_byUserId(user.id)
  clients = Clients.get_clients_for_trainer(trainer.id)

  {:ok, assign(socket, clients: clients)}


end

  def render(assigns) do
    ~H"""
    <h1> Hello </h1>
    <table>

    <thead>
    <tr>
    <th> Name
    </th>
    <th>
    Age
    </th>

    </tr>
    </thead>
    <tbody>

  <%= for client <- @clients do %>


   <tr>
   <td> <%= client.user.name %> </td>
   <td> <%= client.age %> </td>
   <td>  <.link
                          navigate={~p"/clients/#{client.id}"}
                          class="inline-flex items-center px-3 py-2 border border-transparent text-sm leading-4 font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-colors duration-200"
                        >
                        View
                        </.link>
                        </td>
   </tr>

    <%end%>
    </tbody>
    </table>
    """


  end

end
