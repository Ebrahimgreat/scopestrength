defmodule CrohnjobsWeb.ChangeProgramme do

  use CrohnjobsWeb, :live_view
  alias Crohnjobs.Programmes
  alias Crohnjobs.Trainers
  alias Crohnjobs.Trainers.Trainer
  alias Crohnjobs.Repo
  alias Crohnjobs.Programmes.Programme
  alias Crohnjobs.Programmes.ProgrammeUser

  import Ecto.Query





  def mount(params, session, socket) do
    user = socket.assigns.current_user
    id = params["id"]
    trainers = Trainers.get_trainer_byUserId(user.id)
    clientProgramme = Repo.get_by(ProgrammeUser, client_id: id, is_active: true)|> Repo.preload(:programme)
    case clientProgramme do
      nil -> nil
      pu -> pu
    end


    programmes = Repo.all(from(Programme, where: [trainer_id: ^trainers.id]))


    {:ok, assign(socket, programmes: programmes, clientProgramme: clientProgramme, client_id: id)}

  end

  def handle_event("unroll", params, socket) do
   id = String.to_integer(params["id"])
   clientProgramme = socket.assigns.clientProgramme
   case Programmes.update_programme_user(clientProgramme,%{is_active: false}) do
    {:ok, _programme}->
      programmeUser = nil
      {:noreply, socket|> put_flash(:info, "Programme Unrolled Successfully")|> assign(:clientProgramme, programmeUser)}
      _ -> {:noreply, socket|> put_flash(:error, "Unable to update the programme")}

   end


  end


  def handle_event("assignProgramme", params, socket) do
   id = String.to_integer(params["id"])

   if socket.assigns.clientProgramme != nil &&  socket.assigns.clientProgramme.programme_id == id do
    {:noreply, socket|> put_flash(:error, "Programme already has user")}

   else
     case socket.assigns.clientProgramme do
    nil ->
      {:ok, programme_user} = Programmes.create_programme_user(%{programme_id: id, client_id: socket.assigns.client_id, is_active: true})

      clientProgramme = programme_user|> Repo.preload(:programme)
      {:noreply, socket|> put_flash(:info, "Programme Assigned")|> assign(:clientProgramme, clientProgramme)}


      existing->  Programmes.update_programme_user(existing, %{is_active: false})


      {:ok, programme_user} = Programmes.create_programme_user(%{programme_id: id, client_id: socket.assigns.client_id, is_active: true})
      updatedProgramme = programme_user|> Repo.preload(:programme)
      {:noreply, socket|> put_flash(:info, "Programme Updated")|> assign(:clientProgramme, updatedProgramme)}

    end
   end



  end

  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-indigo-50 to-purple-100 py-8">
      <div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
        <!-- Header Section -->
        <div class="mb-8">
          <div class="bg-white rounded-xl shadow-lg border-2 border-indigo-200 p-8">
            <div class="flex items-center justify-between">
              <div class="flex items-center space-x-6">
                <div class="w-20 h-20 bg-indigo-600 rounded-full flex items-center justify-center shadow-lg">
                  <svg class="w-10 h-10 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4" />
                  </svg>
                </div>
                <div>
                  <h1 class="text-4xl font-bold text-gray-900">Programme Management</h1>
                  <p class="text-lg text-gray-600 mt-1">Assign or change client's programme enrollment</p>
                </div>
              </div>
              <div class="text-right">
                <.link
                  navigate={~p"/clients/#{@client_id}"}
                  class="inline-flex items-center px-4 py-2 bg-gray-600 hover:bg-gray-700 text-white font-semibold rounded-lg shadow-md transition-all duration-200"
                >
                  <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
                  </svg>
                  Back to Client
                </.link>
              </div>
            </div>
          </div>
        </div>

        <!-- Current Programme Section -->
        <%= if @clientProgramme != nil do %>
          <div class="mb-8">
            <div class="bg-white rounded-xl shadow-lg border-2 border-green-200 overflow-hidden">
              <div class="bg-green-600 px-6 py-4">
                <div class="flex items-center justify-between">
                  <h2 class="text-2xl font-bold text-white flex items-center">
                    <svg class="w-6 h-6 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z" />
                    </svg>
                    Current Programme Enrollment
                  </h2>
                  <div class="bg-green-800 text-white px-4 py-2 rounded-full shadow-lg">
                    <span class="font-bold text-sm">ACTIVE</span>
                  </div>
                </div>
                <p class="text-green-100 mt-1">Currently assigned programme for this client</p>
              </div>

              <div class="p-6">
                <div class="bg-gradient-to-r from-blue-50 to-indigo-50 rounded-xl p-6 border-2 border-blue-200">
                  <div class="flex items-center justify-between">
                    <div class="flex items-center space-x-4">
                      <div class="w-16 h-16 bg-blue-600 rounded-full flex items-center justify-center shadow-lg">
                        <svg class="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                        </svg>
                      </div>
                      <div>
                        <h3 class="text-2xl font-bold text-gray-900"><%= @clientProgramme.programme.name %></h3>
                        <p class="text-gray-600 font-medium">Active Programme</p>
                      </div>
                    </div>
                    <.button
                      phx-click="unroll"
                      phx-value-id={@clientProgramme.programme_id}
                      data-confirm="Are you sure you want to unenroll this client from the programme?"
                      class="bg-red-600 hover:bg-red-700 text-white px-6 py-3 rounded-lg font-bold shadow-lg transition-all duration-200 transform hover:scale-105"
                    >
                      <svg class="w-5 h-5 mr-2 inline" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                      </svg>
                      Unenroll Client
                    </.button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        <% else %>
          <div class="mb-8">
            <div class="bg-white rounded-xl shadow-lg border-2 border-yellow-200 p-8">
              <div class="text-center">
                <div class="w-20 h-20 bg-yellow-400 rounded-full flex items-center justify-center mx-auto mb-4 shadow-lg">
                  <svg class="w-10 h-10 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.996-.833-2.768 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
                  </svg>
                </div>
                <h2 class="text-2xl font-bold text-gray-900 mb-2">No Active Programme</h2>
                <p class="text-lg text-gray-600">This client is not currently enrolled in any programme. Choose from the available programmes below.</p>
              </div>
            </div>
          </div>
        <% end %>

        <!-- Available Programmes Section -->
        <div class="bg-white rounded-xl shadow-lg border-2 border-purple-200">
          <div class="bg-purple-600 px-6 py-4 rounded-t-xl">
            <div class="flex items-center justify-between">
              <h2 class="text-2xl font-bold text-white flex items-center">
                <svg class="w-6 h-6 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
                </svg>
                Available Programmes
              </h2>
              <div class="bg-purple-800 text-white px-4 py-2 rounded-full shadow-lg">
                <span class="font-bold text-sm"><%= length(@programmes) %> available</span>
              </div>
            </div>
            <p class="text-purple-100 mt-1">Click on any programme to assign it to this client</p>
          </div>

          <div class="p-6">
            <%= if length(@programmes) > 0 do %>
              <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                <%= for {programme, index} <- Enum.with_index(@programmes) do %>
                  <div class={"group bg-gradient-to-br rounded-xl p-6 border-2 shadow-lg transition-all duration-200 hover:shadow-xl transform hover:scale-105 #{if @clientProgramme && @clientProgramme.programme_id == programme.id, do: "from-green-100 to-emerald-100 border-green-400", else: "from-blue-50 to-indigo-50 border-blue-200 hover:border-blue-400"}"}>
                    <div class="flex items-start justify-between mb-4">
                      <div class="flex items-center space-x-3">
                        <div class={"w-12 h-12 rounded-full flex items-center justify-center shadow-lg #{if @clientProgramme && @clientProgramme.programme_id == programme.id, do: "bg-green-600", else: "bg-blue-600"}"}>
                          <span class="text-white font-bold text-lg">
                            <%= index + 1 %>
                          </span>
                        </div>
                        <div>
                          <h3 class="text-lg font-bold text-gray-900 group-hover:text-blue-800 transition-colors">
                            <%= programme.name %>
                          </h3>
                          <%= if @clientProgramme && @clientProgramme.programme_id == programme.id do %>
                            <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-bold bg-green-200 text-green-800">
                              <svg class="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                              </svg>
                              ENROLLED
                            </span>
                          <% else %>
                            <span class="text-gray-500 text-sm font-medium">Available for enrollment</span>
                          <% end %>
                        </div>
                      </div>
                    </div>

                    <div class="flex justify-end">
                      <%= if @clientProgramme && @clientProgramme.programme_id == programme.id do %>
                        <div class="bg-gray-200 text-gray-500 px-4 py-2 rounded-lg font-semibold cursor-not-allowed">
                          <svg class="w-4 h-4 mr-2 inline" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                          </svg>
                          Already Assigned
                        </div>
                      <% else %>
                        <.button
                          phx-click="assignProgramme"
                          phx-value-id={programme.id}
                          class="bg-orange-600 hover:bg-orange-700 text-white px-6 py-3 rounded-lg font-bold shadow-lg transition-all duration-200 transform hover:scale-105"
                        >
                          <svg class="w-5 h-5 mr-2 inline" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                          </svg>
                          Assign Programme
                        </.button>
                      <% end %>
                    </div>
                  </div>
                <% end %>
              </div>
            <% else %>
              <!-- Empty State -->
              <div class="text-center py-16 bg-gradient-to-br from-red-50 to-pink-50 rounded-xl border-2 border-red-200">
                <div class="w-20 h-20 bg-red-400 rounded-full flex items-center justify-center mx-auto mb-6 shadow-lg">
                  <svg class="w-10 h-10 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                  </svg>
                </div>
                <h3 class="text-2xl font-bold text-gray-900 mb-2">No Programmes Available</h3>
                <p class="text-lg text-gray-600 mb-4">You haven't created any programmes yet.</p>
                <div class="bg-blue-100 border-2 border-blue-300 rounded-lg p-4 inline-block">
                  <p class="text-blue-800 font-bold">
                    💡 Create programmes first to assign them to clients!
                  </p>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

end
