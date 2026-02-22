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
    {:ok, assign(socket, trainer_id: trainer.id, openProgamme: openProgramme, programmes: myProgramme, name: user.name, newProgramme: newProgramme, delete_confirm_id: nil)}

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
  {:noreply, assign(socket, delete_confirm_id: id)}
end

def handle_event("cancel_delete", _params, socket) do
  {:noreply, assign(socket, delete_confirm_id: nil)}
end

def handle_event("confirm_delete", _params, socket) do
  id = socket.assigns.delete_confirm_id

  programme = Programmes.get_programme!(id)
  case Programmes.delete_programme(programme) do
    {:ok, _programme}->
      programmes = Enum.reject(socket.assigns.programmes, & (&1.id == id))
       {:noreply, socket |> put_flash(:info, "Programme Deleted") |> assign(programmes: programmes, delete_confirm_id: nil)}
    _ ->{:noreply, socket |> put_flash(:error, "An Error has been occured") |> assign(delete_confirm_id: nil)}
  end
end

  def handle_event("duplicateProgramme", %{"id" => id}, socket) do
    id = String.to_integer(id)

    case Programmes.clone_programme(id) do
      {:ok, new_programme} ->
        {:noreply,
         update(socket, :programmes, fn programmes -> [new_programme | programmes] end)
         |> put_flash(:info, "Programme duplicated")}

      {:error, _} ->
        {:noreply, socket |> put_flash(:error, "Failed to duplicate programme")}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="w-full min-h-screen">
    <div class="w-full px-0 sm:px-2 lg:px-4 pt-10 pb-4">
        <div class="w-full px-0 sm:px-2 lg:px-4 py-8">
          <h1 class="text-3xl font-bold tracking-tight text-slate-900">Training Programmes</h1>
          <p class="mt-2 text-slate-600 text-base lg:text-lg">
            Manage your custom training programmes, <%= @name %>
          </p>
        </div>
      </div>

          <div class="w-full px-0 sm:px-2 lg:px-4 py-4">
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
                class="inline-flex items-center gap-2 px-5 py-2.5 rounded-full text-sm font-semibold text-white bg-gradient-to-r from-slate-900 via-slate-800 to-slate-900 shadow-lg shadow-slate-900/20 hover:shadow-xl hover:shadow-slate-900/25 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-slate-900 transition"
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
                        <div class="flex items-center justify-center gap-2">
                          <.link
                            navigate={~p"/trainer/programmes/#{programme.id}"}
                            class="inline-flex items-center rounded-full border border-slate-200 bg-white px-3 py-1.5 text-xs font-semibold text-slate-700 shadow-sm hover:border-slate-300 hover:bg-slate-50 transition"
                          >
                            View
                          </.link>
                          <button
                            type="button"
                            phx-click="duplicateProgramme"
                            phx-value-id={programme.id}
                            class="inline-flex items-center rounded-full border border-slate-200 bg-white px-3 py-1.5 text-xs font-semibold text-slate-700 shadow-sm hover:border-slate-300 hover:bg-slate-50 transition"
                          >
                            Duplicate
                          </button>
                          <button
                            type="button"
                            phx-click="deleteProgramme"
                            phx-value-id={programme.id}
                            class="inline-flex items-center rounded-full border border-rose-200 bg-rose-50 px-3 py-1.5 text-xs font-semibold text-rose-700 shadow-sm hover:border-rose-300 hover:bg-rose-100 transition"
                          >
                            Delete
                          </button>
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
              <svg class="mx-auto h-16 w-16 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
              </svg>
              <h3 class="mt-4 text-lg font-medium text-gray-900">No programmes yet</h3>
              <p class="mt-2 text-gray-500">Get started by creating your first training programme.</p>
              <div class="mt-6">
                <.button
                  type="button"
                  phx-click="addNewProgramme"
                  class="inline-flex items-center gap-2 px-6 py-3 rounded-full text-base font-semibold text-white bg-gradient-to-r from-slate-900 via-slate-800 to-slate-900 shadow-lg shadow-slate-900/20 hover:shadow-xl hover:shadow-slate-900/25 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-slate-900 transition"
                >
                  <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
                  </svg>
                  Create Your First Programme
                </.button>
              </div>
            </div>
          <% end %>




  <%= if @delete_confirm_id do %>
      <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
        <div class="bg-white rounded-2xl shadow-xl p-6 max-w-sm w-full mx-4">
          <div class="flex items-center justify-center w-12 h-12 mx-auto rounded-full bg-rose-100 mb-4">
            <svg class="w-6 h-6 text-rose-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L4.082 16.5c-.77.833.192 2.5 1.732 2.5z"></path>
            </svg>
          </div>
          <h3 class="text-lg font-semibold text-gray-900 text-center">Delete Programme</h3>
          <p class="mt-2 text-sm text-gray-600 text-center">
            Are you sure you want to delete this programme? This action cannot be undone.
          </p>
          <div class="mt-6 flex gap-3 justify-center">
            <button
              type="button"
              phx-click="cancel_delete"
              class="inline-flex items-center rounded-full border border-slate-200 bg-white px-4 py-2 text-sm font-semibold text-slate-700 shadow-sm hover:bg-slate-50 transition"
            >
              Cancel
            </button>
            <button
              type="button"
              phx-click="confirm_delete"
              class="inline-flex items-center rounded-full border border-rose-200 bg-rose-600 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-rose-700 transition"
            >
              Delete
            </button>
          </div>
        </div>
      </div>
      <% end %>

</div>
    """

  end

end
