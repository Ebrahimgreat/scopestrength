defmodule CrohnjobsWeb.ShowClient do
  alias Crohnjobs.Clients
  alias Crohnjobs.Clients.Client
  alias Crohnjobs.Repo
  use CrohnjobsWeb, :live_view

  def mount(params, session, socket) do
  client = Repo.get!(Client,params["id"])|> Repo.preload(:user)
  clientForm = Clients.change_client(client)|>to_form()
  {:ok, assign(socket, client: clientForm)}


  end
  def render(assigns) do
    ~H"""

    <.form for={@client}>
    <.input field={@client[:user][:name]}/>

    </.form>
    <h1> hello From Client page
    </h1>

    """

  end

end
