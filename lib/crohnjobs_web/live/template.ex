defmodule CrohnjobsWeb.Template do
alias Crohnjobs.Trainers
alias CrohnjobsWeb.Template
alias Phoenix.LiveViewTest.View
  use CrohnjobsWeb, :live_view
  alias Crohnjobs.Programmes
  alias Crohnjobs.Programmes.Programme
  alias Crohnjobs.Programmes.ProgrammeTemplate
  alias Crohnjobs.Repo

  def handle_event("updateForm", params, socket) do
    IO.inspect(params)
    name = params["programme_template"]["name"]
    programmeTemplate = socket.assigns.template.data
    case Programmes.update_programme_template(programmeTemplate, %{name: name}) do
      {:ok, _programme}->
        template = %{programmeTemplate | name: name}
        templateForm = Programmes.change_programme_template(template)|>to_form()

        {:noreply, socket|> put_flash(:info, "Template Updated")|> assign(:template, templateForm)}

        _ ->{:noreply,socket|> put_flash(:eror, "SOmething Happend")}
    end
  end
 @spec mount(nil | maybe_improper_list() | map(), any(), any()) :: {:ok, any()}
 def mount(params, session, socket) do
  user = socket.assigns.current_user
  trainer = Trainers.get_trainer_byUserId(user.id)
  template_id = String.to_integer(params["template_id"])
  programme_id = String.to_integer(params["id"])

  case Repo.get(ProgrammeTemplate, template_id) do
    nil ->
      {:ok,
       socket
       |> put_flash(:error, "Template not found")
       |> redirect(to: "/programmes")}

    template ->
      programme = Repo.get(Programme, template.programme_id)

      case programme.trainer_id == trainer.id do
        true ->
          template = Repo.preload(template, programmeDetails: [:exercise])
          template_changeset = Programmes.change_programme_template(template) |> to_form()

          {:ok,
           assign(socket,
             template: template_changeset,
             template_id: template_id
           )}

        false ->
          {:ok,
           socket
           |> put_flash(:error, "Template not found")
           |> redirect(to: "/programmes")}
      end
  end
end

  def render(assigns) do
    ~H"""
    <div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <!-- Header Section -->
      <div class="mb-8">
        <div class="flex items-center justify-between mb-6">
          <div class="flex items-center space-x-4">
            <.link
              navigate={~p"/programmes/#{@template.data.programme_id}"}
              class="inline-flex items-center text-sm text-gray-500 hover:text-gray-700 transition-colors duration-200"
            >
              <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
              </svg>
              Back to Programme
            </.link>
            <svg class="w-4 h-4 text-gray-400" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z" clip-rule="evenodd" />
            </svg>
            <h1 class="text-3xl font-bold text-gray-900">
              <%= @template.data.name %>
            </h1>
          </div>
          <.link
            navigate={~p"/programmes/#{@template.data.programme_id}/template/#{@template.data.id}/details"}
            class="inline-flex items-center px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white font-medium rounded-lg shadow-sm transition-colors duration-200"
          >
            <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
            </svg>
            View Details
          </.link>
        </div>
      </div>

      <!-- Template Settings Section -->
      <div class="mb-8">
        <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <h2 class="text-xl font-semibold text-gray-800 mb-4">Template Settings</h2>
          <.form phx-submit="updateForm" for={@template} class="space-y-4">
            <div class="flex items-end space-x-4">
              <div class="flex-1">
                <.input
                  label="Template Name"
                  field={@template[:name]}
                  class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                  placeholder="Enter template name"
                />
              </div>
              <.button class="inline-flex items-center px-4 py-2 bg-green-600 hover:bg-green-700 text-white font-medium rounded-lg shadow-sm transition-colors duration-200">
                <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12" />
                </svg>
                Update Name
              </.button>
            </div>
          </.form>
        </div>
      </div>

      <!-- Programme Details Section -->
      <div class="bg-white rounded-lg shadow-sm border border-gray-200">
        <div class="px-6 py-4 border-b border-gray-200">
          <div class="flex items-center justify-between">
            <h2 class="text-xl font-semibold text-gray-800">Programme Details</h2>
            <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
              <%= length(@template.data.programmeDetails) %> exercise<%= if length(@template.data.programmeDetails) != 1, do: "s" %>
            </span>
          </div>
        </div>

        <div class="p-6">
          <%= if length(@template.data.programmeDetails) > 0 do %>
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              <%= for {programmeDetail, index} <- Enum.with_index(@template.data.programmeDetails) do %>
                <div class="bg-gradient-to-br from-gray-50 to-white border border-gray-200 rounded-lg p-4 hover:shadow-md transition-shadow duration-200">
                  <div class="flex items-center justify-between mb-3">
                    <div class="flex items-center space-x-2">
                      <div class="w-8 h-8 bg-indigo-100 rounded-full flex items-center justify-center">
                        <span class="text-sm font-semibold text-indigo-600">
                          <%= index + 1 %>
                        </span>
                      </div>
                      <span class="text-xs font-medium text-gray-500 uppercase tracking-wide"> <%= programmeDetail.exercise.name%></span>
                    </div>
                  </div>

                  <div class="space-y-3">
                    <div class="flex items-center justify-between">
                      <div class="flex items-center space-x-2">
                        <svg class="w-4 h-4 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 12l3-3 3 3 4-4M8 21l4-4 4 4M3 4h18M4 4h16v12a1 1 0 01-1 1H5a1 1 0 01-1-1V4z" />
                        </svg>
                        <span class="text-sm font-medium text-gray-600">Sets</span>
                      </div>
                      <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                        <%= programmeDetail.set %>
                      </span>
                    </div>

                    <div class="flex items-center justify-between">
                      <div class="flex items-center space-x-2">
                        <svg class="w-4 h-4 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                        </svg>
                        <span class="text-sm font-medium text-gray-600">Reps</span>
                      </div>
                      <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                        <%= programmeDetail.reps %>
                      </span>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          <% else %>
            <!-- Empty State -->
            <div class="text-center py-12">
              <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
              </svg>
              <h3 class="mt-2 text-sm font-medium text-gray-900">No exercises yet</h3>
              <p class="mt-1 text-sm text-gray-500">Add some exercises to get started with this template.</p>
              <div class="mt-6">
                <.link
                  navigate={~p"/programmes/#{@template.data.programme_id}/template/#{@template.data.id}/details"}
                  class="inline-flex items-center px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white font-medium rounded-lg shadow-sm transition-colors duration-200"
                >
                  <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                  </svg>
                  Add Exercises
                </.link>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
