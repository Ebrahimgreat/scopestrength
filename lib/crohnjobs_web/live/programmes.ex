defmodule CrohnjobsWeb.Programmes do
alias Crohnjobs.Trainers
alias Crohnjobs.Programmes

  use CrohnjobsWeb, :live_view

  def mount(params, _session, socket) do
   trainer_id = params["trainer_id"]


    user = socket.assigns.current_user


    openProgramme = false
    newProgramme = Programmes.change_programme(%Programmes.Programme{})|>to_form()
    trainer = Trainers.get_trainer_byUserId(user.id)

    if trainer_id != trainer.id do
      redirect(socket, to: "/")
    end

    programmes = if trainer do
      programmes = Programmes.list_programme()
      Enum.filter(programmes, &(&1.trainer_id == trainer.id))
    else
      []
    end
    myProgramme = Enum.filter(programmes, &(&1.trainer_id == trainer.id))
    {:ok, assign(socket, trainer_id: trainer.id, openProgamme: openProgramme, programmes: myProgramme, name: user.name, newProgramme: newProgramme)}

  end
  def handle_event("addNewProgramme", _params, socket) do

  newProgramme = %{name: "Untitled", description: "untitled", trainer_id: socket.assigns.trainer_id}
case Programmes.create_programme(newProgramme) do
  {:ok, programme}-> {:noreply, update(socket, :programmes, fn programmes->[programme | programmes]end)}
  _ -> {:noreply, socket|> put_flash(:error, "An error has been occured ")}
end

  end
def handle_event("deleteProgramme", %{"id"=> id}, socket) do
  id = String.to_integer(id)

programme = Programmes.get_programme!(id)
IO.inspect(programme)
case Programmes.delete_programme(programme) do
  {:ok, _programme}->
    programmes = Enum.reject(socket.assigns.programmes, & (&1.id == id))
     {:noreply, socket |> put_flash(:info, "Programme Deleted")|> assign(:programmes, programmes)}
  _ ->{:noreply, socket|> put_flash(:error, "An Error has been occured")}

end

end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50">
    <div class="bg-gradient-to-r from-purple-600 to-blue-700 text-white">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <h1 class="text-3xl font-bold tracking-tight">Training Programmes</h1>
          <p class="mt-2 text-purple-100 text-lg">
            Manage your custom training programmes, <%= @name %>
          </p>
        </div>
      </div>

          <div class="px-6 py-4 border-b border-gray-200 bg-gray-50">
            <div class="flex items-center justify-between">
              <h2 class="text-lg font-semibold text-gray-900 flex items-center">
                <svg class="w-5 h-5 mr-2 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
                </svg>
                Your Training Programmes
              </h2>
              <.button
                type="button"
                phx-click="addNewProgramme"
                class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-purple-600 hover:bg-purple-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500"
              >
                <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
                </svg>
                <%= if @openProgamme, do: "Cancel", else: "Add New Programme" %>
              </.button>
            </div>
            </div>



      <%= if length(@programmes) > 0 do %>
            <div class="overflow-x-auto">
              <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                  <tr>
                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Programme Name
                    </th>
                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Description
                    </th>
                    <th scope="col" class="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                  <%= for programme <- @programmes do %>
                    <tr class="hover:bg-gray-50 transition-colors duration-150">
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div class="flex items-center">
                          <div class="flex-shrink-0 h-10 w-10">
                            <div class="h-10 w-10 rounded-full bg-gradient-to-r from-purple-500 to-blue-600 flex items-center justify-center">
                              <span class="text-sm font-medium text-white">
                                <%= String.first(programme.name) %>
                              </span>
                            </div>
                          </div>
                          <div class="ml-4">
                            <div class="text-sm font-medium text-gray-900">
                              <%= programme.name %>
                            </div>
                          </div>
                        </div>
                      </td>
                      <td class="px-6 py-4">
                        <div class="text-sm text-gray-900 max-w-xs">
                          <%= if programme.description && programme.description != "" do %>
                            <p class="truncate"><%= programme.description %></p>
                          <% else %>
                            <span class="text-gray-400 italic">No description provided</span>
                          <% end %>
                        </div>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap text-center">
                        <.link
                          navigate={~p"/programmes/#{programme.id}"}
                          class="inline-flex items-center px-3 py-2 border border-transparent text-sm leading-4 font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-colors duration-200"
                        >
                          <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path>
                          </svg>
                          View Templates
                        </.link>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap text-center">
                      <.button phx-click="deleteProgramme" phx-value-id={programme.id}>
                      Delete Programme
                      </.button>

                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          <% else %>
            <!-- Empty State -->
            <div class="text-center py-12">
              <svg class="mx-auto h-16 w-16 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
              </svg>
              <h3 class="mt-4 text-lg font-medium text-gray-900">No programmes yet</h3>
              <p class="mt-2 text-gray-500">Get started by creating your first training programme.</p>
              <div class="mt-6">
                <.button
                  type="button"
                  phx-click="addNewProgramme"
                  class="inline-flex items-center px-6 py-3 border border-transparent shadow-sm text-base font-medium rounded-md text-white bg-purple-600 hover:bg-purple-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500"
                >
                  <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
                  </svg>
                  Create Your First Programme
                </.button>
              </div>
            </div>
          <% end %>




</div>
    """

  end

end
