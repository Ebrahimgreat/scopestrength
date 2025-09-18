defmodule CrohnjobsWeb.Exercises do


  alias Crohnjobs.Exercise

alias Crohnjobs.Trainers
  use CrohnjobsWeb, :live_view


  def handle_event("filterExercise",%{"name"=>name},socket) do
    if socket.assigns.filterApplied == name do
     {:noreply, assign(socket,exercises: socket.assigns.exercises)}
    end

    filterApplied = name
   myExercises = case name do
     "All" ->
      Exercise.list_exercises()
      _ -> Enum.filter(socket.assigns.exercises, &(&1.type == name))


    end
    {:noreply, assign(socket, exercises: myExercises, filterApplied: filterApplied)}
  end
  def handle_event("filterExerciseByEquipment",%{"name"=>name}, socket) do
    filterByEquipment = name
   exercises = Enum.filter(socket.assigns.exercises, &(&1.equipment == name))
   {:noreply, assign(socket, exercises: exercises, filterByEquipment: filterByEquipment)}

  end


  def mount(_params, _session, socket) do

    filterApplied = "All"
    filterByEquipment = "All"


     newExerciseForm = to_form(%{name: "Haka", type: "Boo", equipment: "Hala"})



    exercises = Exercise.list_exercises()
    {:ok, assign(socket, newExerciseForm: newExerciseForm, filterApplied: filterApplied, exercises: exercises, filterByEquipment: filterByEquipment)}
  end
  def render(assigns) do
    ~H"""

<div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6">
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
          phx-value-name="Legs"
          class={[
            "px-4 py-2 rounded-md text-sm font-medium transition-all duration-200",
            if(@filterApplied == "Legs",
              do: "bg-blue-600 text-white shadow-md",
              else: "bg-gray-100 hover:bg-gray-200 text-gray-700 hover:shadow-sm"
            )
          ]}
        >
          Legs
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
    <div>
      <h3 class="text-sm font-medium text-gray-700 mb-3 flex items-center">
        <svg class="w-4 h-4 mr-2 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"></path>
        </svg>
        Filter By Equipment
      </h3>
      <div class="flex flex-wrap gap-2">
        <.button
          phx-value-name="Machine"
          phx-click="filterExerciseByEquipment"
          class="px-4 py-2 bg-gray-100 hover:bg-gray-200 text-gray-700 rounded-md text-sm font-medium transition-all duration-200 hover:shadow-sm"
        >
          Machine
        </.button>

        <.button
          phx-value-name="Cables"
          phx-click="filterExerciseByEquipment"
          class="px-4 py-2 bg-gray-100 hover:bg-gray-200 text-gray-700 rounded-md text-sm font-medium transition-all duration-200 hover:shadow-sm"
        >
          Cables
        </.button>

        <.button
          phx-value-name="Barbell"
          phx-click="filterExerciseByEquipment"
          class="px-4 py-2 bg-gray-100 hover:bg-gray-200 text-gray-700 rounded-md text-sm font-medium transition-all duration-200 hover:shadow-sm"
        >
          Barbell
        </.button>

        <.button
          phx-value-name="Dumbbell"
          phx-click="filterExerciseByEquipment"
          class="px-4 py-2 bg-gray-100 hover:bg-gray-200 text-gray-700 rounded-md text-sm font-medium transition-all duration-200 hover:shadow-sm"
        >
          Dumbbell
        </.button>

        <.button
          phx-value-name="Bodyweight"
          phx-click="filterExerciseByEquipment"
          class="px-4 py-2 bg-gray-100 hover:bg-gray-200 text-gray-700 rounded-md text-sm font-medium transition-all duration-200 hover:shadow-sm"
        >
          Bodyweight
        </.button>
      </div>
    </div>
  </div>

  <!-- Results Counter -->
  <div class="mt-6 pt-4 border-t border-gray-200">
    <div class="flex items-center justify-between text-sm text-gray-600">
      <span>
        Showing <%= length(@exercises) %> exercise<%= if length(@exercises) != 1, do: "s" %>
        <%= if @filterApplied != "All" do %>
          for "<%= @filterApplied %>"
        <% end %>
      </span>
      <%= if length(@exercises) == 0 and @filterApplied != "All" do %>
        <span class="text-amber-600 font-medium">No exercises match current filter</span>
      <% end %>
    </div>
  </div>
</div>






     <div class="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
        <%= if length(@exercises) > 0 do %>
          <div class="overflow-x-auto">
            <table class="w-full">
              <thead class="bg-gray-50 border-b border-gray-200">
                <tr>
                  <th class="text-left py-4 px-6 font-semibold text-gray-900">Exercise Name</th>
                  <th class="text-left py-4 px-6 font-semibold text-gray-900">Type</th>
                  <th class="text-left py-4 px-6 font-semibold text-gray-900">Equipment</th>

                </tr>
              </thead>
              <tbody class="divide-y divide-gray-200">
                <%= for exercise <- @exercises do %>
                  <tr class="hover:bg-gray-50 transition-colors duration-150">
                    <td class="py-4 px-6 font-medium text-gray-900"><%= exercise.name %></td>
                    <td class="py-4 px-6 text-gray-600"><%= exercise.type || "N/A" %></td>
                    <td class="py-4 px-6 text-gray-600"><%= exercise.equipment || "None" %></td>


                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        <% else %>
          <div class="text-center py-12">
            <svg class="w-16 h-16 mx-auto text-gray-400 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
            </svg>
            <h3 class="text-lg font-medium text-gray-900 mb-2">No exercises found</h3>
            <p class="text-gray-500 mb-4">Get started by adding your first exercise.</p>
            <.button
              type="button"
              phx-click="openAddExercise"
              class="bg-blue-600 hover:bg-blue-700 text-white px-6 py-2 rounded-lg font-medium transition-colors duration-200"
            >
              Add Your First Exercise
            </.button>
          </div>
        <% end %>
      </div>










    """

  end

end
