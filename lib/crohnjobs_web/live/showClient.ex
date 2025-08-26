defmodule CrohnjobsWeb.ShowClient do
  alias Crohnjobs.Clients
  alias Crohnjobs.Clients.Client
  alias Crohnjobs.Repo
  use CrohnjobsWeb, :live_view

  def mount(params, session, socket) do
  client = Repo.get!(Client,params["id"])
  clientForm = Clients.change_client(client)|>to_form()
  {:ok, assign(socket, client: clientForm)}


  end
  def render(assigns) do
    ~H"""

Hi
    """

  end

end
