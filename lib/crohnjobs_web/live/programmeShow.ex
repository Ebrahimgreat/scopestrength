defmodule CrohnjobsWeb.ProgrammeShow do

  use CrohnjobsWeb, :live_view
  alias Crohnjobs.Programmes



  def handle_event("deleteTemplate", params, socket) do
  id = String.to_integer(params["id"])
  programmeTemplate = Programmes.get_programme_template!(id)
  case Programmes.delete_programme_template(programmeTemplate) do
    {:ok, _template}->
      programme = %{socket.assigns.programme.data | programmeTemplates: Enum.reject(socket.assigns.programme.data.programmeTemplates, &(&1.id == id))}
      updated_form = Programmes.change_programme(programme)|> to_form()
      {:noreply, socket|> put_flash(:info, "Template Deleted")|> assign(:programme, updated_form)}
  end

  end

  def handle_event("updateForm", params, socket) do
    target = Enum.at(params["_target"],1)
    IO.inspect(target)
    case target do
      "name" ->  Programmes.update_programme(socket.assigns.programme.data, %{name: params["programme"]["name"]})
      programme = %{socket.assigns.programme | name: params["programme"]["name"]}
      myProgramme = Programmes.change_programme(programme)|>to_form()
      {:noreply, socket|> put_flash(:info, "Programme Name Updated")|> assign(:programme, myProgramme)}
      "description"->Programmes.update_programme(socket.assigns.programme.data, %{description:  params["programme"]["description"]})
      programme = %{socket.assigns.programme | description: params["programme"]["description"]}
      myProgramme = Programmes.change_programme(programme)|>to_form()
      {:noreply, socket|> put_flash(:info, "Programme Description Updated")|> assign(:programme, myProgramme)}
      _ -> {:noreply, put_flash(socket,:error, "Something Happened")}
    end


  end
  def handle_event("addTemplate", _params, socket) do
    id = socket.assigns.programme.data.id

    newTemplate = %{name: "Untitled", programme_id: id}
    programmeTemplates = socket.assigns.programme.data.programmeTemplates
    case Programmes.create_programme_template(newTemplate) do
      {:ok, template}->
        programme = %{socket.assigns.programme.data | programmeTemplates: programmeTemplates ++ [template]}
        updated_form = Programmes.change_programme(programme)|>to_form()
        {:noreply, socket|>  put_flash(:info, "Template Added")|>  assign(:programme, updated_form)}
        _ -> {:noreply, socket|> put_flash(:error, "An error has occured")}
    end



  end
 def mount(%{"id"=>id}, session, socket) do
  programme = Programmes.get_programme_with_template!(id)
  myProgramme = Programmes.change_programme(programme)|>to_form()

  {:ok, assign(socket,  programme: myProgramme, programmeId: id)}


 end
  def render(assigns) do
    ~H"""

    <.button phx-click="addTemplate">
    Add Template
    </.button>
    <h1> Programme </h1>
  <.form phx-change="updateForm" for={@programme}>
  <.input label="Name" field={@programme[:name]} type="text"/>
  <.input label="description" field={@programme[:description]}/>



  <h2>
  Templates
  </h2>


  </.form>

  <table>
  <thead>
  <tr>
  <th>
  Name
  </th>
  <th>
  Action
  </th>
  </tr>
</thead>
<tbody>

  <%= for template <- @programme.data.programmeTemplates do %>
  <tr>
  <td> <%= template.name %></td>
  <td> <.button phx-click="deleteTemplate" phx-value-id={template.id}> Delete </.button>
  </td>
  <td>


  <.link  navigate={~p"/programmes/#{@programmeId}/template/#{template.id}"}  class="inline-flex items-center px-3 py-2 border border-transparent text-sm leading-4 font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-colors duration-200">
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
