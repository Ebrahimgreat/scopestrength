defmodule CrohnjobsWeb.StrengthProgress do
alias Crohnjobs.Exercise
alias Crohnjobs.CustomExercises.CustomExercise
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
    {:noreply, assign(socket, filterApplied: "All", exercises: filtered_exercises)}

 end

 def handle_event("filterExercise",%{"name"=>name},socket) do
  if socket.assigns.filterApplied == name do
   {:noreply, assign(socket,exercises: socket.assigns.exercises)}
  end

  filterApplied = name
 myExercises = case name do
   "All" ->
   socket.assigns.allExercises
    _ -> Enum.filter(socket.assigns.allExercises, &(&1.type == name))


  end
  {:noreply, assign(socket, exercises: myExercises, filterApplied: filterApplied)}
end





def mount(params, session, socket) do
  user = socket.assigns.current_user
  trainer = Trainers.get_trainer!(user.id)
  client_id= String.to_integer(params["id"])


  customExercises = Repo.all(from c in CustomExercise, where: c.trainer_id==^trainer.id)
  exercises = Exercise.list_exercises()++customExercises


  {:ok, assign(socket, filterApplied: "All", searchExercise: "", exercises: exercises, client_id: client_id, allExercises: exercises)}
end

  def render(assigns) do
    ~H"""
   <div class="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">

   <div class="flex items-center justify-between mb-6">
    <h2 class="text-lg font-semibold text-gray-900">Filter Exercises</h2>
    <%= if @filterApplied != "All" do %>
      <.button
        phx-click="filterExercise"
        phx-value-name="All"
        class="text-sm bg-gray-100 hover:bg-gray-200 text-gray-700 px-3 py-1 rounded-md transition-colors duration-200"
      >
        Clear All Filters
      </.button>
    <% end %>
  </div>


  <!-- Active Filter Display -->
  <%= if @filterApplied != "All" do %>
    <div class="mb-4 p-3 bg-blue-50 border border-blue-200 rounded-lg">
      <div class="flex items-center justify-between">
        <div class="flex items-center space-x-2">
          <svg class="w-4 h-4 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707v6.586a1 1 0 01-1.447.894l-4-2A1 1 0 018 18.586v-4.586a1 1 0 00-.293-.707L1.293 7.293A1 1 0 011 6.586V4z"></path>
          </svg>
          <span class="text-sm font-medium text-blue-800">Active Filter:</span>
          <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
            <%= @filterApplied %>
          </span>
        </div>
      </div>
    </div>
  <% end %>

  <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
    <!-- Filter By Type -->
    <div>
      <h3 class="text-sm font-medium text-gray-700 mb-3 flex items-center">
        <svg class="w-4 h-4 mr-2 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z"></path>
        </svg>
        Filter By Type
      </h3>
      <div class="flex flex-wrap gap-2">
        <.button
          phx-click="filterExercise"
          phx-value-name="All"
          class={[
            "px-4 py-2 rounded-md text-sm font-medium transition-all duration-200",
            if(@filterApplied == "All",
              do: "bg-blue-600 text-white shadow-md",
              else: "bg-gray-100 hover:bg-gray-200 text-gray-700 hover:shadow-sm"
            )
          ]}
        >
          All Types
        </.button>

        <.button
          phx-click="filterExercise"
          phx-value-name="Chest"
          class={[
            "px-4 py-2 rounded-md text-sm font-medium transition-all duration-200",
            if(@filterApplied == "Chest",
              do: "bg-blue-600 text-white shadow-md",
              else: "bg-gray-100 hover:bg-gray-200 text-gray-700 hover:shadow-sm"
            )
          ]}
        >
          Chest
        </.button>
        <.button
          phx-click="filterExercise"
          phx-value-name="Back"
          class={[
            "px-4 py-2 rounded-md text-sm font-medium transition-all duration-200",
            if(@filterApplied == "Back",
              do: "bg-blue-600 text-white shadow-md",
              else: "bg-gray-100 hover:bg-gray-200 text-gray-700 hover:shadow-sm"
            )
          ]}
        >
          Back
        </.button>

        <.button
          phx-click="filterExercise"
          phx-value-name="Abs"
          class={[
            "px-4 py-2 rounded-md text-sm font-medium transition-all duration-200",
            if(@filterApplied == "Abs",
              do: "bg-blue-600 text-white shadow-md",
              else: "bg-gray-100 hover:bg-gray-200 text-gray-700 hover:shadow-sm"
            )
          ]}
        >
          Abs
        </.button>


        <.button
          phx-click="filterExercise"
          phx-value-name="Biceps"
          class={[
            "px-4 py-2 rounded-md text-sm font-medium transition-all duration-200",
            if(@filterApplied == "Biceps",
              do: "bg-blue-600 text-white shadow-md",
              else: "bg-gray-100 hover:bg-gray-200 text-gray-700 hover:shadow-sm"
            )
          ]}
        >
          Biceps
        </.button>
        <.button
          phx-click="filterExercise"
          phx-value-name="Triceps"
          class={[
            "px-4 py-2 rounded-md text-sm font-medium transition-all duration-200",
            if(@filterApplied == "Triceps",
              do: "bg-blue-600 text-white shadow-md",
              else: "bg-gray-100 hover:bg-gray-200 text-gray-700 hover:shadow-sm"
            )
          ]}
        >
          Triceps
        </.button>


        <.button
          phx-click="filterExercise"
          phx-value-name="Quads"
          class={[
            "px-4 py-2 rounded-md text-sm font-medium transition-all duration-200",
            if(@filterApplied == "Quads",
              do: "bg-blue-600 text-white shadow-md",
              else: "bg-gray-100 hover:bg-gray-200 text-gray-700 hover:shadow-sm"
            )
          ]}
        >
          Quads
        </.button>

        <.button
          phx-click="filterExercise"
          phx-value-name="Hamstrings"
          class={[
            "px-4 py-2 rounded-md text-sm font-medium transition-all duration-200",
            if(@filterApplied == "Hamstrings",
              do: "bg-blue-600 text-white shadow-md",
              else: "bg-gray-100 hover:bg-gray-200 text-gray-700 hover:shadow-sm"
            )
          ]}
        >
          Hamstrings
        </.button>

        <.button
          phx-click="filterExercise"
          phx-value-name="Glutes"
          class={[
            "px-4 py-2 rounded-md text-sm font-medium transition-all duration-200",
            if(@filterApplied == "Glutes",
              do: "bg-blue-600 text-white shadow-md",
              else: "bg-gray-100 hover:bg-gray-200 text-gray-700 hover:shadow-sm"
            )
          ]}
        >
          Glutes
        </.button>

        <.button
          phx-click="filterExercise"
          phx-value-name="Shoulders"
          class={[
            "px-4 py-2 rounded-md text-sm font-medium transition-all duration-200",
            if(@filterApplied == "Shoulders",
              do: "bg-blue-600 text-white shadow-md",
              else: "bg-gray-100 hover:bg-gray-200 text-gray-700 hover:shadow-sm"
            )
          ]}
        >
          Shoulders
        </.button>
      </div>
    </div>

    <!-- Filter By Equipment -->

  </div>



   <.form phx-change="searchExercise">
   <.input label="Search Exercise" name="searchExercise" value={@searchExercise} field={@searchExercise}/>
   </.form>

   <table class="w-full">
   <thead class="bg-gray-50 border-b border-gray-200">
   <tr>
   <th class="text-left py-4 px-6 font-semibold text-gray-900"> Exercise</th>
   <th class="text-left py-4 px-6 font-semibold text-gray-900"> Type</th>
   <th class="text-left py-4 px-6 font-semibold text-gray-900"> Equipment</th>
   <th class="text-left py-4 px-6 font-semibold text-gray-900">
   View</th>
   </tr>
   </thead>
   <tbody class="divide-y divide-gray-200">
   <%=for exercise<-@exercises do %>
   <tr>
   <td class="py-4 px-6 font-medium text-gray-900"><%= exercise.name %></td>
                    <td class="py-4 px-6 text-gray-600"><%= exercise.type || "N/A" %></td>
                    <td class="py-4 px-6 text-gray-600"><%= exercise.equipment || "None" %></td>
                    <td class="py-4 px-6 text-gray-600">
                  <%=if Map.has_key?(exercise, :trainer_id) do%>
                  <.link navigate={~p"/clients/#{@client_id}/strengthProgress/#{exercise.id}?custom=yes"}>
                   <.button>
                   View
                   </.button>
                   </.link>
                   <%=else%>
                   <.link navigate={~p"/clients/#{@client_id}/strengthProgress/#{exercise.id}?custom=no"}>
                   <.button>
                   View
                   </.button>
                   </.link>
                   <%end%>
                    </td>
                </tr>
                    <%end%>

   </tbody>
   </table>





   </div>
    """
  end


end
