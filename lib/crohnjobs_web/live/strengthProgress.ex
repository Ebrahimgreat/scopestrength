defmodule CrohnjobsWeb.StrengthProgress do
  alias Crohnjobs.Exercise
  alias Crohnjobs.Trainers
  import Ecto.Query
  alias Crohnjobs.Repo
  use CrohnjobsWeb, :live_view

  def handle_event("searchExercise", params, socket) do
    search = params["searchExercise"] || ""

    filtered_exercises =
      if search == "" do
        socket.assigns.allExercises
      else
        Enum.filter(socket.assigns.allExercises, fn ex ->
          String.contains?(String.downcase(ex.name), String.downcase(search))
        end)
      end

    {:noreply,
     assign(socket,
       filterApplied: "All",
       exercises: filtered_exercises,
       searchExercise: search
     )}
  end

  def handle_event("filterExercise", %{"name" => name}, socket) do
    if socket.assigns.filterApplied == name do
      {:noreply, assign(socket, exercises: socket.assigns.exercises)}
    end

    filterApplied = name

    myExercises =
      case name do
        "All" ->
          socket.assigns.allExercises

        _ ->
          Enum.filter(socket.assigns.allExercises, &(&1.type == name))
      end

    {:noreply, assign(socket, exercises: myExercises, filterApplied: filterApplied)}
  end

  def mount(params, session, socket) do
    user = socket.assigns.current_user
    _trainer = Trainers.get_trainer_byUserId(user.id)
    client_id = String.to_integer(params["id"])

    exercises =
      Repo.all(
        from e in Crohnjobs.Exercises.Exercise,
          where: e.is_custom == false or e.user_id == ^user.id,
          order_by: [asc: e.name]
      )

    {:ok,
     assign(socket,
       filterApplied: "All",
       searchExercise: "",
       exercises: exercises,
       client_id: client_id,
       allExercises: exercises
     )}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-slate-50 via-white to-blue-50 py-8">
      <div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 space-y-6">
        <div class="bg-white border border-blue-100 shadow-xl rounded-2xl p-6 md:p-8">
          <div class="flex items-start justify-between gap-4">
            <div>
              <p class="text-sm font-semibold text-blue-600 uppercase tracking-wide">
                Strength Dashboard
              </p>
              <h1 class="text-3xl font-bold text-gray-900 mt-1">Strength Progress</h1>
              <p class="text-gray-600 mt-2">Browse and track strength exercises for this client.</p>
              <div class="mt-4 flex flex-wrap gap-3 text-sm">
                <span class="inline-flex items-center gap-2 bg-blue-50 text-blue-800 px-3 py-1 rounded-full border border-blue-100">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M8 6h13M8 12h13M8 18h13M3 6h.01M3 12h.01M3 18h.01"
                    />
                  </svg>
                  <span class="font-semibold">Total Exercises:</span>
                  <span class="font-bold">{length(@allExercises)}</span>
                </span>
                <span class="inline-flex items-center gap-2 bg-green-50 text-green-800 px-3 py-1 rounded-full border border-green-100">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M5 13l4 4L19 7"
                    />
                  </svg>
                  <span class="font-semibold">Showing:</span>
                  <span class="font-bold">{length(@exercises)}</span>
                </span>
              </div>
            </div>
            <div class="hidden md:flex items-center gap-3 bg-blue-50 text-blue-900 px-4 py-3 rounded-xl border border-blue-100">
              <svg
                class="w-10 h-10 text-blue-600"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M3 7h18M3 12h18M3 17h18"
                />
              </svg>
              <div>
                <p class="text-xs font-semibold uppercase">Active Filter</p>
                <p class="text-lg font-bold text-gray-900">{@filterApplied}</p>
              </div>
            </div>
          </div>
        </div>

        <div class="bg-white border border-gray-200 shadow-sm rounded-2xl p-6 space-y-4">
          <div class="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
            <div class="w-full md:max-w-xl">
              <form phx-change="searchExercise" class="space-y-2">
                <label class="text-sm font-semibold text-gray-700">Search exercises</label>
                <div class="relative">
                  <svg
                    class="w-5 h-5 text-gray-400 absolute left-3 top-1/2 -translate-y-1/2"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M21 21l-4.35-4.35m0 0A7.5 7.5 0 105.65 5.65a7.5 7.5 0 0011 11z"
                    />
                  </svg>
                  <input
                    type="text"
                    name="searchExercise"
                    value={@searchExercise}
                    placeholder="Search by name (e.g. Bench Press)"
                    class="w-full pl-10 pr-4 py-3 rounded-xl border border-gray-200 bg-gray-50 focus:bg-white focus:border-blue-500 focus:ring-2 focus:ring-blue-200 text-gray-900"
                  />
                </div>
              </form>
            </div>
            <div class="flex flex-wrap gap-2">
              <%= for type <- ["All", "Chest", "Back", "Abs", "Biceps", "Triceps", "Quads", "Hamstrings", "Glutes", "Shoulders"] do %>
                <.button
                  phx-click="filterExercise"
                  phx-value-name={type}
                  class={
                    "px-4 py-2 rounded-full text-sm font-semibold transition-all duration-200 " <>
                      if(@filterApplied == type,
                        do: "bg-blue-600 text-white shadow-md shadow-blue-200",
                        else: "bg-gray-100 text-gray-700 hover:bg-gray-200"
                      )
                  }
                >
                  {type}
                </.button>
              <% end %>
            </div>
          </div>

          <%= if @filterApplied != "All" do %>
            <div class="flex items-center justify-between bg-blue-50 border border-blue-100 rounded-xl px-4 py-3">
              <div class="flex items-center gap-2 text-sm text-blue-800">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 4v16m8-8H4"
                  />
                </svg>
                <span class="font-semibold">Filter applied:</span>
                <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-bold bg-white border border-blue-200 text-blue-700">
                  {@filterApplied}
                </span>
              </div>
              <.button
                phx-click="filterExercise"
                phx-value-name="All"
                class="text-sm font-semibold text-blue-700 hover:text-blue-900 bg-white border border-blue-200 px-3 py-1.5 rounded-lg shadow-sm"
              >
                Reset filter
              </.button>
            </div>
          <% end %>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <%= if Enum.empty?(@exercises) do %>
            <div class="col-span-1 md:col-span-2">
              <div class="bg-white border border-dashed border-gray-300 rounded-2xl p-10 text-center shadow-sm">
                <div class="inline-flex items-center justify-center w-16 h-16 rounded-full bg-blue-50 text-blue-700 mb-4">
                  <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M9.75 9.75l4.5 4.5m0-4.5l-4.5 4.5M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                    />
                  </svg>
                </div>
                <h3 class="text-xl font-bold text-gray-900">No exercises found</h3>
                <p class="text-gray-600 mt-2">Try adjusting the search or clearing filters.</p>
                <div class="mt-4 flex justify-center">
                  <.button
                    phx-click="filterExercise"
                    phx-value-name="All"
                    class="bg-blue-600 hover:bg-blue-700 text-white px-5 py-2.5 rounded-lg font-semibold"
                  >
                    Clear filters
                  </.button>
                </div>
              </div>
            </div>
          <% else %>
            <%= for exercise <- @exercises do %>
              <div class="bg-white rounded-2xl border border-gray-200 shadow-sm p-5 flex flex-col gap-3">
                <div class="flex items-start justify-between gap-3">
                  <div>
                    <p class="text-xs font-semibold text-blue-600 uppercase tracking-wide">
                      Exercise
                    </p>
                    <h3 class="text-xl font-bold text-gray-900">{exercise.name}</h3>
                  </div>
                  <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-bold bg-blue-50 text-blue-800 border border-blue-100">
                    {exercise.type || "N/A"}
                  </span>
                </div>

                <div class="flex flex-wrap gap-2 text-sm text-gray-700">
                  <span class="inline-flex items-center gap-2 px-3 py-1 rounded-lg bg-gray-50 border border-gray-200">
                    <svg
                      class="w-4 h-4 text-gray-500"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M9 17v-2a2 2 0 012-2h2a2 2 0 012 2v2m2-9h-1a2 2 0 01-2-2V4M7 8H6a2 2 0 00-2 2v1m0 4v1a2 2 0 002 2h1"
                      />
                    </svg>
                    <span class="font-semibold">Equipment:</span>
                    <span class="text-gray-900">{exercise.equipment || "None"}</span>
                  </span>
                  <span class={[
                    "inline-flex items-center gap-2 px-3 py-1 rounded-lg border text-xs font-bold",
                    if(exercise.is_custom,
                      do: "bg-amber-50 border-amber-200 text-amber-800",
                      else: "bg-emerald-50 border-emerald-200 text-emerald-800"
                    )
                  ]}>
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M12 11c0 1.657-1.343 3-3 3H5v3h3c3.314 0 6-2.686 6-6V6h3V3h-3a3 3 0 00-3 3v5z"
                      />
                    </svg>
                    {if exercise.is_custom, do: "Custom Exercise", else: "Standard Library"}
                  </span>
                </div>

                <div class="flex items-center justify-between pt-1">
                  <p class="text-sm text-gray-500">Open to view progress history</p>
                  <%= if exercise.is_custom do %>
                    <.link navigate={
                      ~p"/trainer/clients/#{@client_id}/strengthProgress/#{exercise.id}?custom=yes"
                    }>
                      <.button class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg font-semibold shadow-sm">
                        View progress
                      </.button>
                    </.link>
                  <% else %>
                    <.link navigate={
                      ~p"/trainer/clients/#{@client_id}/strengthProgress/#{exercise.id}?custom=no"
                    }>
                      <.button class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg font-semibold shadow-sm">
                        View progress
                      </.button>
                    </.link>
                  <% end %>
                </div>
              </div>
            <% end %>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
