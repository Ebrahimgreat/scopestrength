defmodule CrohnjobsWeb.ClientDashboard do
alias Crohnjobs.Programmes.ProgrammeUser
alias Crohnjobs.Programmes
alias Crohnjobs.Programmes.Programme
alias Crohnjobs.Accounts.Trainer
alias Crohnjobs.Clients.Client
alias Crohnjobs.DownloadProgramme
alias Crohnjobs.Invites
alias Crohnjobs.Repo
alias Crohnjobs.Training.{Workout, WorkoutDetails}
import Ecto.Query
  use CrohnjobsWeb, :live_view

  def handle_event("submit_invite_code", %{"code" => code}, socket) do
    user = socket.assigns.current_user
    client = socket.assigns.client

    case Invites.redeem_invite(code, user.email) do
      {:ok, trainer_id} ->
        case Invites.link_client_to_trainer(client.id, trainer_id) do
          {:ok, updated_client} ->
            client = Repo.get!(Client, client.id) |> Repo.preload(trainer: :user)
            {:noreply, socket
              |> assign(client: client, invite_code: "")
              |> put_flash(:info, "Successfully linked with your trainer!")}

          {:error, _} ->
            {:noreply, socket |> put_flash(:error, "Failed to link with trainer")}
        end

      {:error, :invalid_code} ->
        {:noreply, socket |> put_flash(:error, "Invalid invite code")}

      {:error, :already_used} ->
        {:noreply, socket |> put_flash(:error, "This invite code has already been used")}

      {:error, :email_mismatch} ->
        {:noreply, socket |> put_flash(:error, "This invite code was created for a different email address")}

      {:error, _} ->
        {:noreply, socket |> put_flash(:error, "Something went wrong")}
    end
  end

  def handle_event("update_invite_code", %{"code" => code}, socket) do
    {:noreply, assign(socket, invite_code: code)}
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
    client = Repo.get_by(Client, %{user_id: user.id}) |> Repo.preload(trainer: :user)

    currentProgramme = Repo.get_by(ProgrammeUser, %{client_id: client.id})
    |> case do
      nil -> nil
      pu -> Repo.preload(pu, [programme: [programmeTemplates: [programmeDetails: :exercise]]])
    end

    # Get recent workouts
    recent_workouts =
      from(w in Workout,
        where: w.client_id == ^client.id,
        order_by: [desc: w.date],
        limit: 5,
        preload: [workoutDetails: :exercise]
      )
      |> Repo.all()

    # Get exercise progress (unique exercises the client has done)
    exercise_progress =
      from(wd in WorkoutDetails,
        join: w in Workout, on: wd.workout_id == w.id,
        where: w.client_id == ^client.id,
        join: e in assoc(wd, :exercise),
        group_by: [e.id, e.name],
        select: %{exercise_id: e.id, name: e.name, total_sets: count(wd.id)}
      )
      |> Repo.all()

    {:ok, assign(socket,
      report: false,
      client: client,
      current_programme: currentProgramme,
      invite_code: "",
      recent_workouts: recent_workouts,
      exercise_progress: exercise_progress
    )}
  end
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto px-4 py-6 space-y-6">
      <!-- Header with Date -->
      <div class="flex items-center justify-between">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">Dashboard</h1>
          <p class="text-gray-500 text-sm mt-1">
            <%= Calendar.strftime(DateTime.utc_now(), "%A, %B %d, %Y") %>
          </p>
        </div>
        <div class="text-right">
          <%= if @client.trainer do %>
            <p class="text-sm text-gray-500">Your Trainer</p>
            <p class="font-semibold text-gray-900"><%= @client.trainer.user.name %></p>
          <% else %>
            <span class="px-3 py-1 bg-yellow-100 text-yellow-800 rounded-full text-sm">No trainer assigned</span>
          <% end %>
        </div>
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
                    <div class="w-12 h-12 bg-emerald-100 rounded-xl flex items-center justify-center">
                      <svg class="w-6 h-6 text-emerald-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path>
                      </svg>
                    </div>
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

        <%= if Enum.empty?(@exercise_progress) do %>
          <div class="p-8 text-center">
            <p class="text-gray-500">No exercises tracked yet</p>
          </div>
        <% else %>
          <div class="p-4 grid grid-cols-2 sm:grid-cols-3 gap-3">
            <%= for exercise <- @exercise_progress do %>
              <.link
                navigate={~p"/client/strengthProgress/#{exercise.exercise_id}"}
                class="p-4 bg-gray-50 hover:bg-emerald-50 rounded-xl border border-gray-200 hover:border-emerald-300 transition-all"
              >
                <p class="font-medium text-gray-900 text-sm truncate"><%= exercise.name %></p>
                <p class="text-xs text-gray-500 mt-1"><%= exercise.total_sets %> total sets</p>
              </.link>
            <% end %>
          </div>
        <% end %>
      </div>

      <%= if @client.trainer == nil do %>
        <!-- Invite Code Entry -->
        <div class="bg-white rounded-2xl shadow-lg p-6 border border-gray-100">
          <div class="flex items-center space-x-3 mb-4">
            <div class="p-2 bg-emerald-100 rounded-lg">
              <svg class="w-6 h-6 text-emerald-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z"></path>
              </svg>
            </div>
            <h2 class="text-xl font-bold text-gray-900">Have an invite code?</h2>
          </div>
          <p class="text-gray-600 mb-4">Enter the invite code from your trainer to connect with them.</p>
          <form phx-submit="submit_invite_code" class="space-y-4">
            <div>
              <input
                type="text"
                name="code"
                value={@invite_code}
                phx-change="update_invite_code"
                placeholder="Enter invite code (e.g., ABC12345)"
                class="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500 transition-all duration-200 font-mono text-lg tracking-wider uppercase"
              />
            </div>
            <.button
              type="submit"
              class="bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-700 hover:to-teal-700 text-white px-6 py-3 rounded-xl shadow-lg hover:shadow-xl transition-all duration-200 font-semibold"
            >
              Connect with Trainer
            </.button>
          </form>
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
                    <div class="px-4 py-3 flex items-center justify-between">
                      <span class="font-medium text-gray-800"><%= detail.exercise.name %></span>
                      <div class="flex items-center space-x-4 text-sm text-gray-600">
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


end
