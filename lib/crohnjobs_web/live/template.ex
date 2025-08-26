defmodule CrohnjobsWeb.Template do
alias CrohnjobsWeb.Template
alias Phoenix.LiveViewTest.View
  use CrohnjobsWeb, :live_view
  alias Crohnjobs.Programmes
  alias Crohnjobs.Programmes
  alias Crohnjobs.Programmes.ProgrammeTemplate
  alias Crohnjobs.Repo

  def handle_event("updateForm", %{"name"=>name}, socket) do





    {:noreply, assign(socket, template: socket.assigns.template)}

  end
 def mount(params, session, socket) do
id =  String.to_integer(params["template_id"])

  template = Repo.get!(ProgrammeTemplate,id)|> Repo.preload(:programmeDetails)
  templateChangeset= Programmes.change_programme_template(template)|> to_form()
  {:ok, assign(socket, template: templateChangeset,  template_id: id)}

 end
  def render(assigns) do
    ~H"""
    {@template.data.name}
    <.form phx-change="updateForm" for={@template}>
    <.input  label="name" field={@template[:name]}/>
    </.form>

    <div class="border">



  <.link  navigate={~p"/programmes/#{@template.data.programme_id}/template/#{@template.data.id}/details"}  class="inline-flex items-center px-3 py-2 border border-transparent text-sm leading-4 font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-colors duration-200">
                        View
    </.link>


    <%=for programmeDetail <-@template.data.programmeDetails do %>

Set
    <%= programmeDetail.set%>
    Repos
    <%= programmeDetail.reps%>


    <%end%>
    </div>




    """

  end

end
