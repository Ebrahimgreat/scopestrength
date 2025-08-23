defmodule CrohnjobsWeb.Programmes do
alias Crohnjobs.Trainers
alias Crohnjobs.Programmes

  use CrohnjobsWeb, :live_view

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    openProgramme = false
    newProgramme = Programmes.change_programme(%Programmes.Programme{})|>to_form()
    trainer = Trainers.get_trainer_byUserId(user.id)

    programmes = if trainer do
      programmes = Programmes.list_programme()
      Enum.filter(programmes, &(&1.trainer_id == trainer.id))
    else
      []
    end
    myProgramme = Enum.filter(programmes, &(&1.trainer_id == trainer.id))
    {:ok, assign(socket, trainer_id: trainer.id, openProgamme: openProgramme, programmes: myProgramme, name: user.name, newProgramme: newProgramme)}

  end


  def render(assigns) do
    ~H"""
    <h1> A list of Your Programmes

{@name}
    </h1>

    <.button>
    Add New Programme
   </.button>
    <ul>


    <%=for programme <- @programmes do%>
    <li><.link navigate={~p"/programmes/templates#{programme.id}"}>
    <%= programme.name %>
    </.link>
    </li>
    <%end%>
    </ul>

    <.form phx-submit="addNewProgramme" for={@newProgramme}>
    <.input label="name" field={@newProgramme[:name]}/>
    <.input label="description" field={@newProgramme[:description]}/>
    <.button>
    Submit
    </.button>

    </.form>

    """

  end

end
