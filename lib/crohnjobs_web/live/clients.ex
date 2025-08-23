defmodule CrohnjobsWeb.Clients do
  use CrohnjobsWeb, :live_view
alias Crohnjobs.Clients


  def mount(_params, _session, socket) do
    clients =  Clients.list_clients()
   {:ok, assign(socket, clients: clients)}

  end
  def render(assigns) do
    ~H"""
   {length(@clients)}

    end

    """

  end




end
