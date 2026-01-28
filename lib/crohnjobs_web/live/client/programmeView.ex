defmodule CrohnjobsWeb.Client.ProgrammeView do
  use CrohnjobsWeb, :live_view

  alias Crohnjobs.Clients.Client
  alias Crohnjobs.Programmes.ProgrammeUser
  alias Crohnjobs.Repo

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    client = Repo.get_by(Client, %{user_id: user.id})

    current_programme =
      Repo.get_by(ProgrammeUser, %{client_id: client.id})
      |> case do
        nil -> nil
        pu -> Repo.preload(pu, [programme: [programmeTemplates: [programmeDetails: :exercise]]])
      end

    # Calculate muscle group volume across all templates
    muscle_group_volume =
      case current_programme do
        nil -> %{}
        programme_user ->
          programme_user.programme.programmeTemplates
          |> Enum.flat_map(fn template -> template.programmeDetails end)
          |> Enum.group_by(fn detail -> if detail.exercise.muscle, do: detail.exercise.muscle.name, else: "Unknown" end)
          |> Enum.map(fn {muscle_group, details} ->
            total_sets = details
              |> Enum.map(&String.to_integer(&1.set))
              |> Enum.sum()
            {muscle_group, total_sets}
          end)
          |> Map.new()
      end

    # Calculate per-template volume
    template_volumes =
      case current_programme do
        nil -> %{}
        programme_user ->
          programme_user.programme.programmeTemplates
          |> Enum.map(fn template ->
            volume = template.programmeDetails
              |> Enum.group_by(fn detail -> if detail.exercise.muscle, do: detail.exercise.muscle.name, else: "Unknown" end)
              |> Enum.map(fn {muscle_group, details} ->
                total_sets = details
                  |> Enum.map(&String.to_integer(&1.set))
                  |> Enum.sum()
                {muscle_group, total_sets}
              end)
              |> Map.new()
            {template.id, volume}
          end)
          |> Map.new()
      end

    {:ok, assign(socket,
      current_programme: current_programme,
      muscle_group_volume: muscle_group_volume,
      template_volumes: template_volumes
    )}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto px-4 py-6 space-y-6">
      <!-- Header -->
      <div class="flex items-center space-x-3">
        <.link
          navigate={~p"/client"}
          class="inline-flex items-center text-sm text-gray-500 hover:text-gray-700 transition-colors"
        >
          <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
          </svg>
          Back
        </.link>
        <h1 class="text-2xl font-bold text-gray-900">My Programme</h1>
      </div>

      <%= if @current_programme do %>
        <!-- Programme Info -->
        <div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
          <div class="px-5 py-4 border-b border-gray-100">
            <h2 class="text-lg font-semibold text-gray-900"><%= @current_programme.programme.name %></h2>
            <%= if @current_programme.programme.description do %>
              <p class="text-sm text-gray-500 mt-1"><%= @current_programme.programme.description %></p>
            <% end %>
          </div>
        </div>

        <!-- Overall Muscle Group Volume -->
        <%= if map_size(@muscle_group_volume) > 0 do %>
          <div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
            <div class="px-5 py-4 border-b border-gray-100">
              <h2 class="text-lg font-semibold text-gray-900">Weekly Muscle Group Volume</h2>
              <p class="text-sm text-gray-500 mt-1">Total sets per muscle group across all sessions</p>
            </div>
            <div class="p-5">
              <div class="grid grid-cols-2 sm:grid-cols-3 gap-3">
                <%= for {muscle_group, total_sets} <- @muscle_group_volume do %>
                  <div class="bg-gradient-to-br from-orange-50 to-amber-50 border border-orange-200 rounded-xl p-4 hover:shadow-md transition-all duration-200">
                    <p class="text-sm font-semibold text-gray-700"><%= muscle_group %></p>
                    <div class="flex items-center justify-between mt-2">
                      <span class="text-xs text-gray-500">Total Sets</span>
                      <span class="inline-flex items-center justify-center px-3 py-1 bg-gradient-to-r from-orange-500 to-amber-500 text-white text-sm font-bold rounded-full">
                        <%= total_sets %>
                      </span>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        <% end %>

        <!-- Templates with Per-Template Volume -->
        <div class="space-y-4">
          <%= for template <- @current_programme.programme.programmeTemplates do %>
            <div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
              <div class="px-5 py-4 bg-gray-50 border-b border-gray-200">
                <h3 class="font-semibold text-gray-900"><%= template.name %></h3>
              </div>

              <!-- Per-Template Volume -->
              <%= if Map.has_key?(@template_volumes, template.id) and map_size(@template_volumes[template.id]) > 0 do %>
                <div class="px-5 py-3 border-b border-gray-100 bg-orange-50/50">
                  <p class="text-xs font-semibold text-gray-600 mb-2">Session Volume</p>
                  <div class="flex flex-wrap gap-2">
                    <%= for {muscle_group, total_sets} <- @template_volumes[template.id] do %>
                      <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-orange-100 text-orange-800">
                        <%= muscle_group %>: <%= total_sets %> sets
                      </span>
                    <% end %>
                  </div>
                </div>
              <% end %>

              <!-- Exercises -->
              <div class="divide-y divide-gray-100">
                <%= for detail <- template.programmeDetails do %>
                  <div class="px-5 py-3 flex items-center justify-between">
                    <div>
                      <span class="font-medium text-gray-800"><%= detail.exercise.name %></span>
                      <span class="ml-2 text-xs text-gray-400"><%= if detail.exercise.muscle, do: detail.exercise.muscle.name, else: "N/A" %></span>
                    </div>
                    <div class="flex items-center space-x-4 text-sm text-gray-600">
                      <span class="px-2 py-0.5 bg-blue-50 text-blue-700 rounded text-xs font-medium"><%= detail.set %> sets</span>
                      <span class="px-2 py-0.5 bg-green-50 text-green-700 rounded text-xs font-medium"><%= detail.reps %> reps</span>
                      <%= if detail.rir do %>
                        <span class="px-2 py-0.5 bg-gray-100 text-gray-600 rounded text-xs font-medium">RIR <%= detail.rir %></span>
                      <% end %>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>
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
