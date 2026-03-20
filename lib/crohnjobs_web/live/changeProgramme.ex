defmodule CrohnjobsWeb.ChangeProgramme do

  use CrohnjobsWeb, :live_view
  alias Crohnjobs.Programmes
  alias Crohnjobs.Trainers
  alias Crohnjobs.Trainers.Trainer
  alias Crohnjobs.Clients
  alias Crohnjobs.Repo
  alias Crohnjobs.Programmes.Programme
  alias Crohnjobs.Programmes.ProgrammeUser
  alias Crohnjobs.Notifications

  import Ecto.Query





  def mount(params, session, socket) do
    user = socket.assigns.current_user
    trainer = Trainers.get_trainer_byUserId(user.id)
    client_id = String.to_integer(params["id"])

    case Repo.get(Crohnjobs.Clients.Client, client_id) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Client Not found")
         |> push_navigate(to: "/trainer/clients")}

      client ->
        case client.trainer_id == trainer.id do
          true ->
            clientProgramme = Repo.get_by(ProgrammeUser, client_id: client_id, is_active: true) |> Repo.preload(:programme)
            programmes = Repo.all(from(Programme, where: [user_id: ^user.id]))

            {:ok, assign(socket, programmes: programmes, clientProgramme: clientProgramme, client_id: client_id)}

          false ->
            {:ok,
             socket
             |> put_flash(:error, "Client Does not exist")
             |> push_navigate(to: "/trainer/clients")}
        end
    end
  end

  def handle_event("unroll", params, socket) do
    id = String.to_integer(params["id"])
    clientProgramme = socket.assigns.clientProgramme

    result = Repo.transaction(fn ->
      case Programmes.update_programme_user(clientProgramme, %{is_active: false}) do
        {:ok, _programme} ->
          # Create notification
          {:ok, notification} = Notifications.create_notification(%{
            actor_id: socket.assigns.current_user.id,
            actor_type: "trainer",
            recipient_id: socket.assigns.client_id,
            recipient_type: "client",
            type: "programme_unenrolled",
            data: %{programme_id: clientProgramme.programme_id}
          })
          notification

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)

    case result do
      {:ok, notification} ->
        # Broadcast notification
        Phoenix.PubSub.broadcast(
          Crohnjobs.PubSub,
          "notifications:client:#{socket.assigns.client_id}",
          {:notification, notification}
        )

        {:noreply, socket |> put_flash(:info, "Programme Unrolled Successfully") |> assign(:clientProgramme, nil)}

      {:error, _} ->
        {:noreply, socket |> put_flash(:error, "Unable to update the programme")}
    end
  end


  def handle_event("assignProgramme", params, socket) do
    id = String.to_integer(params["id"])

    if socket.assigns.clientProgramme != nil && socket.assigns.clientProgramme.programme_id == id do
      {:noreply, socket |> put_flash(:error, "Programme already has user")}
    else
      result = Repo.transaction(fn ->
        case socket.assigns.clientProgramme do
          nil ->
            {:ok, programme_user} = Programmes.create_programme_user(%{
              programme_id: id,
              client_id: socket.assigns.client_id,
              is_active: true
            })

            # Create notification
            {:ok, notification} = Notifications.create_notification(%{
              actor_id: socket.assigns.current_user.id,
              actor_type: "trainer",
              recipient_id: socket.assigns.client_id,
              recipient_type: "client",
              type: "programme_assigned",
              data: %{programme_id: id}
            })

            {programme_user |> Repo.preload(:programme), notification}

          existing ->
            Programmes.update_programme_user(existing, %{is_active: false})

            {:ok, programme_user} = Programmes.create_programme_user(%{
              programme_id: id,
              client_id: socket.assigns.client_id,
              is_active: true
            })

            # Create notification
            {:ok, notification} = Notifications.create_notification(%{
              actor_id: socket.assigns.current_user.id,
              actor_type: "trainer",
              recipient_id: socket.assigns.client_id,
              recipient_type: "client",
              type: "programme_updated",
              data: %{programme_id: id, previous_programme_id: existing.programme_id}
            })

            {programme_user |> Repo.preload(:programme), notification}
        end
      end)

      case result do
        {:ok, {updated_programme, notification}} ->
          # Broadcast to PubSub
          Phoenix.PubSub.broadcast(
            Crohnjobs.PubSub,
            "notifications:client:#{socket.assigns.client_id}",
            {:notification, notification}
          )

          flash_msg = if socket.assigns.clientProgramme, do: "Programme Updated", else: "Programme Assigned"
          {:noreply, socket |> put_flash(:info, flash_msg) |> assign(:clientProgramme, updated_programme)}

        {:error, _reason} ->
          {:noreply, socket |> put_flash(:error, "Failed to assign programme")}
      end
    end
  end

  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <div class="w-full">
      <!-- Header -->
      <div class="mb-6">
        <div class="flex items-center justify-between">
          <div>
            <h1 class="text-2xl font-semibold text-slate-900">Programme Management</h1>
            <p class="text-sm text-slate-600 mt-1">Assign or change client's programme enrollment</p>
          </div>
          <.link
            navigate={~p"/clients/#{@client_id}"}
            class="inline-flex items-center px-3 py-2 border border-slate-300 text-sm font-medium rounded-md text-slate-700 bg-white hover:bg-slate-50"
          >
            Back to Client
          </.link>
        </div>
      </div>

      <!-- Current Programme Section -->
      <%= if @clientProgramme != nil do %>
        <div class="mb-6">
          <div class="bg-white border border-slate-200 rounded-lg p-6">
            <div class="flex items-center justify-between mb-4">
              <h2 class="text-lg font-semibold text-slate-900">Current Programme</h2>
              <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-emerald-100 text-emerald-700">
                <div class="w-1.5 h-1.5 rounded-full bg-emerald-500"></div>
                Active
              </span>
            </div>
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-medium text-slate-900"><%= @clientProgramme.programme.name %></p>
                <p class="text-sm text-slate-500 mt-1">Currently assigned programme</p>
              </div>
              <.button
                phx-click="unroll"
                phx-value-id={@clientProgramme.programme_id}
                data-confirm="Are you sure you want to unenroll this client from the programme?"
                class="inline-flex items-center px-3 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-red-600 hover:bg-red-700"
              >
                Unenroll Client
              </.button>
            </div>
          </div>
        </div>
      <% else %>
        <div class="mb-6">
          <div class="text-center py-12 bg-slate-50/50 rounded-lg border border-slate-200">
            <div class="inline-flex items-center justify-center w-12 h-12 rounded-full bg-slate-100 mb-3">
              <svg class="w-6 h-6 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.996-.833-2.768 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
              </svg>
            </div>
            <h3 class="text-base font-medium text-slate-900 mb-1">No Active Programme</h3>
            <p class="text-sm text-slate-500">This client is not currently enrolled in any programme</p>
          </div>
        </div>
      <% end %>

      <!-- Available Programmes Section -->
      <div>
        <div class="mb-4">
          <h2 class="text-lg font-semibold text-slate-900">Available Programmes</h2>
          <p class="text-sm text-slate-600 mt-1"><%= length(@programmes) %> total</p>
        </div>

        <%= if length(@programmes) > 0 do %>
          <div class="bg-white border border-slate-200 rounded-lg overflow-hidden">
            <table class="w-full">
              <thead class="bg-slate-50 border-b border-slate-200">
                <tr>
                  <th class="text-left px-6 py-3 text-xs font-medium text-slate-600 uppercase tracking-wider">
                    Programme
                  </th>
                  <th class="text-left px-6 py-3 text-xs font-medium text-slate-600 uppercase tracking-wider">
                    Status
                  </th>
                  <th class="text-right px-6 py-3 text-xs font-medium text-slate-600 uppercase tracking-wider">
                    Action
                  </th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-200">
                <%= for programme <- @programmes do %>
                  <tr class="hover:bg-slate-50 transition-colors">
                    <td class="px-6 py-4">
                      <div class="text-sm font-medium text-slate-900"><%= programme.name %></div>
                    </td>
                    <td class="px-6 py-4">
                      <%= if @clientProgramme && @clientProgramme.programme_id == programme.id do %>
                        <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-emerald-100 text-emerald-700">
                          <div class="w-1.5 h-1.5 rounded-full bg-emerald-500"></div>
                          Enrolled
                        </span>
                      <% else %>
                        <span class="text-sm text-slate-500">Available</span>
                      <% end %>
                    </td>
                    <td class="px-6 py-4 text-right">
                      <%= if @clientProgramme && @clientProgramme.programme_id == programme.id do %>
                        <span class="text-sm text-slate-400">Already assigned</span>
                      <% else %>
                        <.button
                          phx-click="assignProgramme"
                          phx-value-id={programme.id}
                          class="inline-flex items-center px-3 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-purple-600 hover:bg-purple-700"
                        >
                          Assign Programme
                        </.button>
                      <% end %>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        <% else %>
          <!-- Empty State -->
          <div class="text-center py-16 bg-slate-50/50 rounded-lg border border-slate-200">
            <div class="inline-flex items-center justify-center w-12 h-12 rounded-full bg-slate-100 mb-3">
              <svg class="w-6 h-6 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
            </div>
            <h3 class="text-base font-medium text-slate-900 mb-1">No programmes yet</h3>
            <p class="text-sm text-slate-500">Create programmes first to assign them to clients</p>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

end
