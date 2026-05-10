defmodule ScopestrengthWeb.ClientDashboard do
alias Scopestrength.Notifications.Notification
alias Scopestrength.Programmes.ProgrammeUser
alias Scopestrength.Programmes
alias Scopestrength.Programmes.Programme
alias Scopestrength.Accounts.Trainer
alias Scopestrength.Clients.Client
alias Scopestrength.DownloadProgramme
alias Scopestrength.Repo
alias Scopestrength.Training.{Workout, WorkoutDetails}
import Ecto.Query
  use ScopestrengthWeb, :live_view


  def handle_event("filterExercise", %{"id" => id}, socket) do
    muscle_id = String.to_integer(id)
    filtered = Enum.filter(socket.assigns.all_exercise_progress, &(&1.muscle_id == muscle_id))
    {:noreply, assign(socket, exercise_progress: filtered, filterApplied: muscle_id)}
  end

  def handle_event("resetFilters", _, socket) do
    {:noreply, assign(socket, exercise_progress: socket.assigns.all_exercise_progress, filterApplied: nil)}
  end


  def handle_event("mark_notification_read", %{"id" => notification_id}, socket) do
    notification = Notifications.get_notification!(notification_id)

    {:ok, _updated} = Notifications.update_notification(notification, %{
      read_at: DateTime.utc_now()
    })

    # Update the notifications list
    notifications =
      Enum.map(socket.assigns.notifications, fn n ->
        if n.id == String.to_integer(notification_id) do
          %{n | read_at: DateTime.utc_now()}
        else
          n
        end
      end)

    {:noreply, assign(socket, notifications: notifications)}
  end

  def handle_event("mark_all_read", _params, socket) do
    client = socket.assigns.client
    from(n in Notification,
      where: n.recipient_type == "client" and
             n.recipient_id == ^client.id and
             is_nil(n.read_at)
    )
    |> Repo.update_all(set: [read_at: DateTime.utc_now()])
    notifications =
      Enum.map(socket.assigns.notifications, fn n ->
        %{n | read_at: DateTime.utc_now()}
      end)

    {:noreply, assign(socket, notifications: notifications)}
  end

  def handle_event("downloadProgramme", _, socket) do
    programme =
    Repo.get!(Programme, socket.assigns.current_programme.programme_id)
    |> Repo.preload(programmeTemplates: [programmeDetails: :exercise])
    IO.inspect(programme.id)
    DownloadProgramme.downloadProgramme(%{programme: programme})
     {:noreply, assign(socket, report: true)}
    end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    client = case Repo.get_by(Client, %{user_id: user.id}) do
      nil -> nil
      c -> Repo.preload(c, trainer: :user)
    end

    currentProgramme =
      if client do
        from(pu in ProgrammeUser,
          where: pu.client_id == ^client.id and pu.is_active == true,
          order_by: [desc: pu.inserted_at],
          limit: 1
        )
        |> Repo.one()
        |> case do
          nil -> nil
          pu -> Repo.preload(pu, [programme: [programmeTemplates: [programmeDetails: :exercise]]])
        end
      else
        nil
      end

    if connected?(socket) && client do
      Phoenix.PubSub.subscribe(
        Scopestrength.PubSub,
        "notifications:client:#{client.id}"
      )
    end

    notifications =
      if client do
        Repo.all(
          from n in Notification,
            where: n.recipient_type == "client" and n.recipient_id == ^client.id and is_nil(n.read_at),
            order_by: [desc: n.inserted_at],
            limit: 10
        )
      else
        []
      end

    recent_workouts =
      if client do
        from(w in Workout,
          where: w.client_id == ^client.id,
          order_by: [desc: w.date],
          limit: 5,
          preload: [workoutDetails: :exercise]
        )
        |> Repo.all()
      else
        []
      end

    exercise_progress =
      if client do
        from(wd in WorkoutDetails,
          join: w in Workout, on: wd.workout_id == w.id,
          where: w.client_id == ^client.id,
          join: e in assoc(wd, :exercise),
          group_by: [e.id, e.name],
          select: %{exercise_id: e.id, name: e.name, muscle_id: e.muscle_id, total_sets: count(wd.id)}
        )
        |> Repo.all()
      else
        []
      end


      #Get Muscles

      muscles = Scopestrength.Exercises.list_mucles()

    {:ok, assign(socket,
      report: false,
      client: client,
      filterApplied: nil,
      current_programme: currentProgramme,
      recent_workouts: recent_workouts,
      exercise_progress: exercise_progress,
      all_exercise_progress: exercise_progress,
      notifications: notifications,
      notification_count: length(notifications),
      muscles: muscles
    )}
  end
  def handle_info({:notification, %Notification{} = notification}, socket) do
    notifications = [notification | socket.assigns.notifications] |> Enum.take(10)

    {:noreply,
     socket
     |> assign(:notifications, notifications)
     |> assign(:notification_count, length(notifications))}
  end

  def handle_info(_, socket), do: {:noreply, socket}

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto px-4 py-6 space-y-6">
      <!-- Header with Date and Profile -->
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div class="flex items-center gap-4">
          <.link navigate={~p"/client/settings"} class="flex-shrink-0 group">
            <%= if @client && @client.profile_picture_url do %>
              <img
                src={@client.profile_picture_url}
                alt="Profile"
                class="w-12 h-12 sm:w-16 sm:h-16 rounded-full object-cover border-2 border-emerald-200 group-hover:border-emerald-400 transition-colors"
              />
            <% else %>
              <div class="w-12 h-12 sm:w-16 sm:h-16 rounded-full bg-gradient-to-br from-emerald-400 to-teal-500 flex items-center justify-center text-white text-lg sm:text-xl font-bold border-2 border-emerald-200 group-hover:border-emerald-400 transition-colors">
                <%= get_user_initials(@client) %>
              </div>
            <% end %>
          </.link>
          <div>
            <h1 class="text-xl sm:text-2xl font-bold text-gray-900">Dashboard</h1>
            <p class="text-gray-500 text-xs sm:text-sm mt-1">
              <%= Calendar.strftime(DateTime.utc_now(), "%A, %B %d, %Y") %>
            </p>
          </div>
        </div>
        <div class="flex items-center gap-3">
          <div class="text-left sm:text-right">
            <%= if @client && @client.trainer do %>
              <p class="text-sm text-gray-500">Your Trainer</p>
              <p class="font-semibold text-gray-900 text-sm sm:text-base"><%= @client.trainer.user.name %></p>
            <% else %>
              <span class="px-3 py-1 bg-yellow-100 text-yellow-800 rounded-full text-sm">No trainer assigned</span>
            <% end %>
          </div>
          <.link
            navigate={~p"/client/settings"}
            class="p-2 hover:bg-gray-100 rounded-lg transition-colors"
            title="Settings"
          >
            <svg class="w-6 h-6 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"></path>
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
            </svg>
          </.link>
        </div>
      </div>

      <!-- Notifications -->
      <div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
        <div class="px-5 py-4 border-b border-gray-100 flex items-center justify-between">
          <div class="flex items-center gap-2">
            <.icon name="hero-bell-solid" class="h-5 w-5 text-emerald-600" />
            <h2 class="text-lg font-semibold text-gray-900">Latest Activities</h2>
          </div>
          <div class="flex items-center gap-3">
            <span class="text-sm text-gray-500"><%= length(@notifications) %> recent</span>
            <%= if Enum.any?(@notifications, &is_nil(&1.read_at)) do %>
              <button
                phx-click="mark_all_read"
                class="text-xs text-emerald-600 hover:text-emerald-700 font-medium transition-colors"
              >
                Mark all read
              </button>
            <% end %>
            <.link
              navigate={~p"/client/notifications"}
              class="text-xs text-emerald-600 hover:text-emerald-700 font-medium transition-colors"
            >
              View all
            </.link>
          </div>
        </div>

        <%= if Enum.empty?(@notifications) do %>
          <div class="p-6 text-sm text-gray-500">No notifications yet.</div>
        <% else %>
          <div class="divide-y divide-gray-100">
            <%= for notification <- @notifications do %>
              <div class="px-5 py-4 flex items-start justify-between gap-4">
                <div>
                  <p class="text-sm font-medium text-gray-900">
                    <%= notification_text(notification) %>
                  </p>
                  <p class="text-xs text-gray-500 mt-1">
                    <%= notification_time(notification) %>
                  </p>
                </div>
                <%= if is_nil(notification.read_at) do %>
                  <span class="mt-1 h-2 w-2 rounded-full bg-emerald-500"></span>
                <% end %>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>

      <!-- Recent Workouts Section -->
      <div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
        <div class="px-5 py-4 border-b border-gray-100 flex items-center justify-between">
          <h2 class="text-lg font-semibold text-gray-900">Recent Workouts</h2>
          <span class="text-sm text-gray-500"><%= length(@recent_workouts) %> workouts</span>
        </div>

        <%= if Enum.empty?(@recent_workouts) do %>
          <div class="p-8 text-center">
            <div class="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-3">
              <svg class="w-8 h-8 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"></path>
              </svg>
            </div>
            <p class="text-gray-500">No workouts logged yet</p>
            <p class="text-sm text-gray-400 mt-1">Start tracking your progress!</p>
          </div>
        <% else %>
          <div class="divide-y divide-gray-100">
            <%= for workout <- @recent_workouts do %>
              <.link navigate={~p"/client/workouts/#{workout.id}"} class="block hover:bg-gray-50 transition-colors">
                <div class="px-5 py-4 flex items-center justify-between">
                  <div class="flex items-center space-x-4">

                    <div>
                      <p class="font-medium text-gray-900"><%= workout.name || "Training Session" %></p>
                      <p class="text-sm text-gray-500">
                        <%= if workout.date do %>
                          <%= Calendar.strftime(workout.date, "%b %d at %I:%M %p") %>
                        <% else %>
                          <%= Calendar.strftime(workout.inserted_at, "%b %d at %I:%M %p") %>
                        <% end %>
                      </p>
                    </div>
                  </div>
                  <div class="flex items-center space-x-3">
                    <span class="px-2 py-1 bg-gray-100 text-gray-600 rounded-lg text-sm">
                      <%= length(workout.workoutDetails) %> sets
                    </span>
                    <svg class="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path>
                    </svg>
                  </div>
                </div>
              </.link>
            <% end %>
          </div>
        <% end %>
      </div>

      <!-- Exercise Progress Section -->
      <div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
        <div class="px-5 py-4 border-b border-gray-100">
          <h2 class="text-lg font-semibold text-gray-900">Your Exercise Progress</h2>
          <p class="text-sm text-gray-500 mt-1">Track your strength gains over time</p>
        </div>

        <!-- Muscle Filters -->
        <div class="px-5 py-3 flex flex-wrap gap-2 border-b border-gray-100">
          <button
            type="button"
            phx-click="resetFilters"
            class="px-3 py-1.5 rounded-full text-xs font-semibold border transition bg-white text-slate-700 border-slate-200 hover:bg-slate-50"
          >
            All
          </button>
          <%= for muscle <- @muscles do %>
            <button
              type="button"
              phx-click="filterExercise"
              phx-value-id={muscle.id}
              class={[
                "px-3 py-1.5 rounded-full text-xs font-semibold border transition",
                if(@filterApplied == muscle.id,
                  do: "bg-emerald-600 text-white border-emerald-600",
                  else: "bg-white text-slate-700 border-slate-200 hover:bg-slate-50"
                )
              ]}
            >
              <%= muscle.name %>
            </button>
          <% end %>
        </div>


        <%= if Enum.empty?(@exercise_progress) do %>
          <div class="p-8 text-center">
            <p class="text-gray-500">No exercises tracked yet</p>
          </div>
        <% else %>
          <div class="p-4 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
            <%= for exercise <- @exercise_progress do %>
              <.link
                navigate={~p"/client/strengthProgress/#{exercise.exercise_id}"}
                class="p-4 bg-gray-50 hover:bg-emerald-50 rounded-xl border border-gray-200 hover:border-emerald-300 transition-all"
              >
                <p class="font-medium text-gray-900 text-sm truncate"><%= exercise.name %></p>
              </.link>
            <% end %>
          </div>
        <% end %>
      </div>

      <%= if is_nil(@client) || is_nil(@client.trainer_id) do %>
        <div class="bg-white rounded-2xl shadow-lg p-6 border border-gray-100">
          <h2 class="text-xl font-bold text-gray-900 mb-2">Find a Trainer</h2>
          <p class="text-gray-600 mb-4">Browse our marketplace to connect with a strength coach.</p>
          <.link navigate={~p"/client/marketplace"} class="inline-flex items-center px-6 py-3 bg-emerald-600 hover:bg-emerald-700 text-white font-semibold rounded-xl transition-colors">
            Browse Trainers
          </.link>
        </div>
      <% end %>

      <!-- Current Programme Section -->
      <%= if @current_programme do %>
        <div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
          <div class="px-5 py-4 border-b border-gray-100 flex items-center justify-between">
            <div>
              <h2 class="text-lg font-semibold text-gray-900">Current Programme</h2>
              <p class="text-sm text-gray-500"><%= @current_programme.programme.name %></p>
            </div>
            <%= if @report == false do %>
              <.button
                phx-click="downloadProgramme"
                class="bg-emerald-600 hover:bg-emerald-700 text-white px-4 py-2 rounded-lg text-sm font-medium flex items-center space-x-2"
              >
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                </svg>
                <span>Download PDF</span>
              </.button>
            <% else %>
              <a
                href="/download/workout"
                class="bg-emerald-600 hover:bg-emerald-700 text-white px-4 py-2 rounded-lg text-sm font-medium flex items-center space-x-2"
              >
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
                </svg>
                <span>Download Now</span>
              </a>
            <% end %>
          </div>

          <%= if @current_programme.programme.description do %>
            <div class="px-5 py-3 bg-gray-50 border-b border-gray-100">
              <p class="text-sm text-gray-600"><%= @current_programme.programme.description %></p>
            </div>
          <% end %>

          <div class="p-5 space-y-4">
            <%= for template <- @current_programme.programme.programmeTemplates do %>
              <div class="border border-gray-200 rounded-lg overflow-hidden">
                <div class="px-4 py-3 bg-gray-50 border-b border-gray-200">
                  <h3 class="font-medium text-gray-900"><%= template.name %></h3>
                </div>
                <div class="divide-y divide-gray-100">
                  <%= for detail <- template.programmeDetails do %>
                    <div class="px-4 py-3 flex items-center justify-between gap-2">
                      <span class="font-medium text-gray-800 min-w-0 truncate"><%= detail.exercise.name %></span>
                      <div class="flex items-center space-x-2 sm:space-x-4 text-xs sm:text-sm text-gray-600 flex-shrink-0">
                        <span><%= detail.set %> sets</span>
                        <span><%= detail.reps %> reps</span>
                        <%= if detail.rir do %>
                          <span class="text-gray-400">RIR <%= detail.rir %></span>
                        <% end %>
                      </div>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      <% else %>
        <div class="bg-gray-50 rounded-xl p-8 text-center border border-gray-200">
          <div class="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-3">
            <svg class="w-8 h-8 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
            </svg>
          </div>
          <p class="text-gray-600 font-medium">No programme assigned yet</p>
          <p class="text-sm text-gray-400 mt-1">Your trainer will assign a programme soon</p>
        </div>
      <% end %>
    </div>
    """
  end

  defp get_user_initials(client) do
    case Repo.preload(client, :user) do
      %{user: %{name: name}} when not is_nil(name) ->
        name
        |> String.split(" ")
        |> Enum.take(2)
        |> Enum.map(&String.first/1)
        |> Enum.join("")
        |> String.upcase()

      _ ->
        "U"
    end
  end

  defp notification_text(%Notification{data: %{"message" => message}}) when is_binary(message), do: message
  defp notification_text(%Notification{data: %{"title" => title}}) when is_binary(title), do: title
  defp notification_text(%Notification{type: type}) when is_binary(type), do: String.replace(type, "_", " ") |> String.capitalize()
  defp notification_text(_), do: "New activity"

  defp notification_time(%Notification{inserted_at: %DateTime{} = inserted_at}) do
    Calendar.strftime(inserted_at, "%b %d, %Y at %I:%M %p")
  end

  defp notification_time(_), do: "Just now"
end
