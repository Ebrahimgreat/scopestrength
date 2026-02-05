defmodule CrohnjobsWeb.ShowClient do
  alias Crohnjobs.Trainers
  alias Crohnjobs.Clients.Client
  alias Crohnjobs.Repo
  alias Crohnjobs.Programmes.ProgrammeUser
  import Ecto.Query
  use CrohnjobsWeb, :live_view

  def mount(params, _session, socket) do
    user = socket.assigns.current_user
    trainer = Trainers.get_trainer_byUserId(user.id)

    id = String.to_integer(params["id"])

    case Repo.get(Client, id) |> Repo.preload(:user) do
      nil ->
        {:ok, socket |> put_flash(:error, "Client Not found") |> redirect(to: "/clients")}

      client ->
        case client.trainer_id == trainer.id do
          true ->
            programmeUser =
              Repo.get_by(ProgrammeUser, client_id: client.id, is_active: true)
              |> Repo.preload(:programme)

            notifications =
              Repo.all(
                from n in Crohnjobs.Notifications.Notification,
                where: n.actor_type == "client" and n.actor_id == ^client.user.id,
                order_by: [desc: n.inserted_at],
                limit: 10
              )

            {:ok, assign(socket, programmeUser: programmeUser, client: client, notifications: notifications)}

          false ->
            {:ok, socket |> put_flash(:error, "Client Does not Exist")}
        end
    end
  end

  def render(assigns) do
    ~H"""
    <div class="w-full min-h-screen">
      <!-- Header -->
      <div class="w-full px-6 lg:px-10 pt-10 pb-4">
        <div class="flex items-center justify-between">
          <div>
            <h1 class="text-3xl lg:text-4xl font-semibold tracking-tight text-slate-900">
              <span class="text-emerald-700">{@client.user.name}</span>
            </h1>
            <p class="mt-2 text-slate-600 text-base lg:text-lg">Client Profile & Management</p>
          </div>
          <.link
            navigate={~p"/trainer/clients"}
            class="inline-flex items-center px-4 py-2 bg-slate-600 hover:bg-slate-700 text-white font-medium rounded-lg transition-colors"
          >
            <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M15 19l-7-7 7-7"
              />
            </svg>
            Back to Clients
          </.link>
        </div>
      </div>

    <!-- Main Content -->
      <div class="w-full px-6 lg:px-10 py-8">
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">

    <!-- Client Information -->
          <div class="bg-white border border-slate-200 rounded-2xl shadow-sm overflow-hidden">
            <div class="px-5 py-4 border-b border-slate-100">
              <h2 class="text-base font-semibold text-slate-900">Client Information</h2>
              <p class="text-xs text-slate-500 mt-1">Client details and personal information</p>
            </div>
            <div class="p-5 space-y-4">
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label class="block text-xs font-medium text-slate-700 mb-1">Full Name</label>
                  <p class="text-sm font-medium text-slate-900">{@client.user.name}</p>
                </div>
                <div>
                  <label class="block text-xs font-medium text-slate-700 mb-1">Age</label>
                  <p class="text-sm font-medium text-slate-900">{@client.age || "Not specified"}</p>
                </div>
              </div>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label class="block text-xs font-medium text-slate-700 mb-1">Height (cm)</label>
                  <p class="text-sm font-medium text-slate-900">
                    {@client.height || "Not specified"}
                  </p>
                </div>
                <div>
                  <label class="block text-xs font-medium text-slate-700 mb-1">Gender</label>
                  <p class="text-sm font-medium text-slate-900">
                    {String.capitalize(@client.sex || "Not specified")}
                  </p>
                </div>
              </div>
              <div>
                <label class="block text-xs font-medium text-slate-700 mb-1">Notes</label>
                <p class="text-sm text-slate-900">{@client.notes || "No notes"}</p>
              </div>
            </div>
          </div>

    <!-- Programme Section -->
          <div class="bg-white border border-slate-200 rounded-2xl shadow-sm overflow-hidden">
            <div class="px-5 py-4 border-b border-slate-100">
              <h2 class="text-base font-semibold text-slate-900">Programme Enrollment</h2>
              <p class="text-xs text-slate-500 mt-1">Current programme assignment</p>
            </div>
            <div class="p-5">
              <%= if @programmeUser != nil do %>
                <div class="mb-4">
                  <div class="flex items-center justify-between mb-3">
                    <div>
                      <p class="text-xs font-medium text-emerald-600 uppercase tracking-wide">
                        Currently Enrolled
                      </p>
                      <p class="text-sm font-medium text-slate-900 mt-1">
                        {@programmeUser.programme.name}
                      </p>
                    </div>
                    <span class="text-xs font-medium text-emerald-700 bg-emerald-100 px-2 py-1 rounded-full">
                      ACTIVE
                    </span>
                  </div>
                  <.link
                    navigate={~p"/trainer/programmes/#{@programmeUser.programme_id}"}
                    class="text-xs text-emerald-600 hover:text-emerald-700 font-medium transition-colors"
                  >
                    View Programme Details →
                  </.link>
                </div>
              <% else %>
                <div class="text-center py-4">
                  <p class="text-sm font-medium text-slate-900 mb-1">No Programme Assigned</p>
                  <p class="text-xs text-slate-500">
                    This client is not currently enrolled in any programme.
                  </p>
                </div>
              <% end %>
              <.link navigate={~p"/trainer/client/#{@client.id}/programme"}>
                <.button class="w-full bg-emerald-600 hover:bg-emerald-700 text-white px-4 py-2 rounded-lg text-sm font-medium transition-colors">
                  Change Programme
                </.button>
              </.link>
            </div>
          </div>

    <!-- Recent Activity -->
          <div class="bg-white border border-slate-200 rounded-2xl shadow-sm overflow-hidden lg:col-span-2">
            <div class="px-5 py-4 border-b border-slate-100">
              <h2 class="text-base font-semibold text-slate-900">Recent Activity</h2>
              <p class="text-xs text-slate-500 mt-1">Latest actions from this client</p>
            </div>
            <div class="p-5">
              <%= if length(@notifications) == 0 do %>
                <div class="text-center py-4">
                  <p class="text-sm text-slate-500">No activity yet</p>
                </div>
              <% else %>
                <div class="divide-y divide-slate-100">
                  <%= for n <- @notifications do %>
                    <.link navigate={activity_link(n, @client.id)} class="flex items-center gap-3 py-3 hover:opacity-70 transition-opacity">
                     
                      <div class="flex-1 min-w-0">
                        <p class="text-sm font-medium text-slate-900"><%=@client.user.name%> <%= activity_label(n) %></p>
                        <p class="text-xs text-slate-400 mt-0.5"><%= format_activity_time(n.inserted_at) %></p>
                      </div>
                      <svg class="w-4 h-4 text-slate-300" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="9 18 15 12 9 6"></polyline>
                      </svg>
                    </.link>
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>

    <!-- Action Sections -->
          <div class="bg-white border border-slate-200 rounded-2xl shadow-sm overflow-hidden">
            <div class="px-5 py-4 border-b border-slate-100">
              <h2 class="text-base font-semibold text-slate-900">Workout Progress</h2>
              <p class="text-xs text-slate-500 mt-1">Monitor the workouts of client</p>
            </div>
            <div class="p-5">
              <.link navigate={~p"/trainer/clients/#{@client.id}/workouts"}>
                <.button class="w-full bg-emerald-600 hover:bg-emerald-700 text-white px-4 py-2 rounded-lg text-sm font-medium transition-colors">
                  View Workout Progress
                </.button>
              </.link>
            </div>
          </div>

          <div class="bg-white border border-slate-200 rounded-2xl shadow-sm overflow-hidden">
            <div class="px-5 py-4 border-b border-slate-100">
              <h2 class="text-base font-semibold text-slate-900">Strength Progress</h2>
              <p class="text-xs text-slate-500 mt-1">Monitor the strength progress of the client</p>
            </div>
            <div class="p-5">
              <.link navigate={~p"/trainer/clients/#{@client.id}/strengthProgress"}>
                <.button class="w-full bg-emerald-600 hover:bg-emerald-700 text-white px-4 py-2 rounded-lg text-sm font-medium transition-colors">
                  View Strength Progress
                </.button>
              </.link>
            </div>
          </div>

          <div class="bg-white border border-slate-200 rounded-2xl shadow-sm overflow-hidden">
            <div class="px-5 py-4 border-b border-slate-100">
              <h2 class="text-base font-semibold text-slate-900">Progress Photos</h2>
              <p class="text-xs text-slate-500 mt-1">View client's visual transformation</p>
            </div>
            <div class="p-5">
              <.link navigate={~p"/trainer/clients/#{@client.id}/progress-photos"}>
                <.button class="w-full bg-emerald-600 hover:bg-emerald-700 text-white px-4 py-2 rounded-lg text-sm font-medium transition-colors">
                  View Progress Photos
                </.button>
              </.link>
            </div>
          </div>

          <div class="bg-white border border-slate-200 rounded-2xl shadow-sm overflow-hidden lg:col-span-2">
            <div class="px-5 py-4 border-b border-slate-100">
              <h2 class="text-base font-semibold text-slate-900">Notes Management</h2>
              <p class="text-xs text-slate-500 mt-1">Add or review additional notes for the client</p>
            </div>
            <div class="p-5">
              <.link navigate={~p"/trainer/clients/#{@client.id}/notes"}>
                <.button class="w-full bg-emerald-600 hover:bg-emerald-700 text-white px-4 py-2 rounded-lg text-sm font-medium transition-colors">
                  Manage Notes
                </.button>
              </.link>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp activity_label(%{type: "workout_created"}), do: "Logged a workout"
  defp activity_label(%{type: "progress_photo_uploaded"}), do: "Uploaded a progress photo"
  defp activity_label(%{type: type}), do: type

  defp activity_link(%{type: "workout_created"}, client_id),
    do: "/trainer/clients/#{client_id}/workouts"

  defp activity_link(%{type: "progress_photo_uploaded"}, client_id),
    do: "/trainer/clients/#{client_id}/progress-photos"

  defp activity_link(_, client_id), do: "/trainer/clients/#{client_id}/workouts"

  defp format_activity_time(datetime) do
    today = DateTime.to_date(DateTime.utc_now())

    if DateTime.to_date(datetime) == today do
      Calendar.strftime(datetime, "Today, %H:%M")
    else
      Calendar.strftime(datetime, "%b %d, %H:%M")
    end
  end
end
