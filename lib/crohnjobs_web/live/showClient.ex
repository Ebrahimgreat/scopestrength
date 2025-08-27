defmodule CrohnjobsWeb.ShowClient do
  alias Phoenix.LiveViewTest.View
  alias Crohnjobs.Programmes.Programme
  alias Crohnjobs.Clients
  alias Crohnjobs.Clients.Client
  alias Crohnjobs.Repo
  alias Crohnjobs.Account
  alias Crohnjobs.Programmes.ProgrammeUser
  use CrohnjobsWeb, :live_view

  def handle_event("updateClient", params, socket) do
    client = socket.assigns.client.data
    name = params["client"]["name"]
    age =  String.to_integer(params["client"]["age"])
    height = String.to_integer(params["client"]["height"])
    sex = params["client"]["sex"]
    notes = params["client"]["notes"]
    case Clients.update_client(client, %{name: name, age: age, sex: sex, height: height, notes: notes }) do
      {:ok, client}->
        client = Clients.change_client(client)|> to_form()
        {:noreply,  socket|> put_flash(:info, "Client Updated")|> assign(client: client)}
        _ -> {:noreply, socket|> put_flash(:error, "Something Happened")}

    end

  end

  def mount(params, session, socket) do
  client = Repo.get!(Client,params["id"])
  programmeUser = Repo.get_by!(ProgrammeUser, client_id: client.id)|> Repo.preload(:programme)
  clientForm = Clients.change_client(client)|>to_form()

  {:ok, assign(socket, programmeUser: programmeUser,  client: clientForm)}


  end
  def render(assigns) do
    ~H"""
     <.form phx-submit="updateClient">
     <.input label="name" field={@client[:name]}/>
     <.input label="age" field={@client[:age]}/>
     <.input label="height" field={@client[:height]}/>
     <.input label="sex" field={@client[:sex]}/>
     <.input label="notes" field={@client[:notes]}/>
     <.button>
     Update
     </.button>
     </.form>

     <h1>
     Programmes Enrolled
     </h1>
     {@programmeUser.programme.name}
     View Programme

     <.link
                          navigate={~p"/programmes/#{@programmeUser.programme_id}"}
                          class="inline-flex items-center px-3 py-2 border border-transparent text-sm leading-4 font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-colors duration-200"
                        >
                        View
                        </.link>



    """

  end

end
