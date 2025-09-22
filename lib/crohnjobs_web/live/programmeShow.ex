defmodule CrohnjobsWeb.ProgrammeShow do

alias Crohnjobs.Trainers
alias Crohnjobs.DownloadProgramme
alias Crohnjobs.Programmes.Programme
alias Crohnjobs.Repo
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
  def handle_event("downloadProgramme", _, socket) do
    programme =
      Repo.get!(Programme, socket.assigns.programmeId)
      |> Repo.preload(programmeTemplates: [programmeDetails: :exercise])
    DownloadProgramme.downloadProgramme(%{programme: programme})
    {:noreply, assign(socket, report: true)}

  end

  def handle_event("updateForm", params, socket) do
    target = Enum.at(params["_target"],1)
    IO.inspect(target)
    case target do
      "name" ->  Programmes.update_programme(socket.assigns.programme.data, %{name: params["programme"]["name"]})
      programme = %{socket.assigns.programme.data | name: params["programme"]["name"]}
      myProgramme = Programmes.change_programme(programme)|>to_form()
      {:noreply, socket|> put_flash(:info, "Programme Name Updated")|> assign(:programme, myProgramme)}

      "description"-> Programmes.update_programme(socket.assigns.programme.data, %{description:  params["programme"]["description"]})
      programme = %{socket.assigns.programme.data | description: params["programme"]["description"]}
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
 @spec mount(map(), any(), any()) :: {:ok, any()}
 def mount(%{"id"=>id}, session, socket) do
  user = socket.assigns.current_user
  trainer = Trainers.get_trainer_byUserId(user.id)

 case Programmes.get_programme_with_template(id) do
  nil -> {:ok, socket |> put_flash(:error, "Programme not found") |> redirect(to: "/programmes")}
  programme->
    case programme.trainer_id == trainer.id do
      true-> myProgramme = Programmes.change_programme(programme)|> to_form()
      {:ok, assign(socket,  programme: myProgramme, programmeId: id, report: false)}
      false ->{:ok, socket|> put_flash(:error, "Programme not found")|>redirect(to: "/programmes")}
    end
  end

 end
 def render(assigns) do
  ~H"""
  <div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
    <!-- Header Section -->
    <div class="mb-8">
      <div class="flex items-center justify-between mb-6">
        <h1 class="text-3xl font-bold text-gray-900">Programme Management</h1>
        <.button
          phx-click="addTemplate"
          class="inline-flex items-center px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white font-medium rounded-lg shadow-sm transition-colors duration-200"
        >
          <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
          </svg>
          Add Template
        </.button>

        <%= if @report == false do %>
        <.button phx-click="downloadProgramme">
      Generate Report
        </.button>
        <%end%>

      </div>

      <%= if @report == true do %>
      <a class="bg-gradient-to-r from-emerald-500 to-emerald-600 hover:from-emerald-600 hover:to-emerald-700 text-white px-6 py-3 rounded-xl shadow-lg hover:shadow-xl transition-all duration-200 flex items-center space-x-2 font-semibold" href="/download/workout">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0l-3-3m3 3l3-3M3 17V7a2 2 0 012-2h6l2 2h6a2 2 0 012 2v10a2 2 0 01-2 2H5a2 2 0 01-2-2z"/>
                </svg>
                <span>Download</span>
              </a>
              <%end%>


      <!-- Programme Details Form -->
      <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h2 class="text-xl font-semibold text-gray-800 mb-4">Programme Details</h2>
        <.form phx-change="updateForm" for={@programme} class="space-y-4">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <.input
              label="Programme Name"
              field={@programme[:name]}
              type="text"
              class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
            />
            <.input
              label="Description"
              field={@programme[:description]}
              class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
            />
          </div>
        </.form>
      </div>
    </div>

    <!-- Templates Section -->
    <div class="bg-white rounded-lg shadow-sm border border-gray-200">
      <div class="px-6 py-4 border-b border-gray-200">
        <div class="flex items-center justify-between">
          <h2 class="text-xl font-semibold text-gray-800">Templates</h2>
          <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
            <%= length(@programme.data.programmeTemplates) %> template<%= if length(@programme.data.programmeTemplates) != 1, do: "s" %>
          </span>
        </div>
      </div>

      <div class="overflow-hidden">
        <%= if length(@programme.data.programmeTemplates) > 0 do %>
          <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200">
              <thead class="bg-gray-50">
                <tr>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Template Name
                  </th>
                  <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody class="bg-white divide-y divide-gray-200">
                <%= for template <- @programme.data.programmeTemplates do %>
                  <tr class="hover:bg-gray-50 transition-colors duration-150">
                    <td class="px-6 py-4 whitespace-nowrap">
                      <div class="flex items-center">
                        <div class="w-2 h-2 bg-green-400 rounded-full mr-3"></div>
                        <div class="text-sm font-medium text-gray-900">
                          <%= template.name %>
                        </div>
                      </div>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                      <div class="flex items-center justify-end space-x-2">
                        <.link
                          navigate={~p"/programmes/#{@programmeId}/template/#{template.id}"}
                          class="inline-flex items-center px-3 py-1.5 border border-transparent text-xs font-medium rounded-md text-indigo-700 bg-indigo-100 hover:bg-indigo-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 transition-colors duration-200"
                        >
                          <svg class="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                          </svg>
                          View
                        </.link>
                        <.button
                          phx-click="deleteTemplate"
                          phx-value-id={template.id}
                          data-confirm="Are you sure you want to delete this template?"
                          class="inline-flex items-center px-3 py-1.5 border border-transparent text-xs font-medium rounded-md text-red-700 bg-red-100 hover:bg-red-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 transition-colors duration-200"
                        >
                          <svg class="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                          </svg>
                          Delete
                        </.button>
                      </div>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        <% else %>
          <!-- Empty State -->
          <div class="text-center py-12">
            <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
            </svg>
            <h3 class="mt-2 text-sm font-medium text-gray-900">No templates</h3>
            <p class="mt-1 text-sm text-gray-500">Get started by creating your first template.</p>
            <div class="mt-6">
              <.button
                phx-click="addTemplate"
                class="inline-flex items-center px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white font-medium rounded-lg shadow-sm transition-colors duration-200"
              >
                <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                </svg>
                Add Template
              </.button>
            </div>
          </div>
        <% end %>
      </div>
    </div>
  </div>
  """
end

end
