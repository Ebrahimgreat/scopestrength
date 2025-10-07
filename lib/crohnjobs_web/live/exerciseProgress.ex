defmodule CrohnjobsWeb.ExerciseProgress do
alias Crohnjobs.Exercise
alias Crohnjobs.Exercises
alias Crohnjobs.Repo
use CrohnjobsWeb, :live_view
import Ecto.Query



def handle_event("filterByType", %{"name"=> name}, socket) do
  if socket.assigns.filterApplied == name do
    {:noreply, assign(socket, exercises: socket.assigns.exercises)}
  end
  filterApplied = name
  myExercises = case name do
    "ALL"-> socket.assigns.allExercises
    _ -> Enum.filter(socket.assigns.allExercises, &(&1.type== name))

  end
  {:noreply, assign(socket, exercises: myExercises, filterApplied: filterApplied)}

end
def handle_event("changeExercise", params, socket) do
  id = String.to_integer(params["id"])
  exerciseSelected = Enum.find(socket.assigns.exercises, fn x-> x.id == id end)
  workout = Repo.all(from w in Crohnjobs.Fitness.WorkoutDetail, where: w.exercise_id == ^id)|> Repo.preload([:exercise, :workout])|>Enum.filter(fn x-> x.workout.client_id == socket.assigns.client_id end)|>Enum.map(fn x-> %{
    name: x.exercise.name,
    date: x.workout.date,
    weight: x.weight,
    set: x.set,
    reps: x.reps,
    rir: x.rir

  }
  end)|> Enum.group_by(fn w-> w.name end)

  series = Enum.map(workout, fn {name, records}->
    %{
      name: name,
      data: Enum.map(records, fn r-> %{
        x: Date.to_string(r.date),
        y: r.weight

      } end)
    }

  end)


  chart =
    LiveCharts.build(%{
      type: :line,
     series: series,
      options: %{
        xaxis: %{type: "datetime", title: %{text: "Date"}},
        yaxis: %{title: %{text: "Weight (kg)"}},
        stroke: %{curve: "smooth"}
      }
    })
IO.inspect(chart)


  {:noreply, assign(socket, workout: workout, chart: chart,
   exerciseSelected: exerciseSelected)}


end
def mount(params, _session, socket) do

  id = String.to_integer(params["id"])


 exerciseSelected = 50

  exercises = Exercise.list_exercises()
  exerciseSelected = Enum.find(exercises, fn x-> x.id == exerciseSelected end)
workout = Repo.all(from w in Crohnjobs.Fitness.WorkoutDetail, where: w.exercise_id == 50)|> Repo.preload([:exercise, :workout])|>Enum.filter(fn x-> x.workout.client_id == id end)|>Enum.map(fn x-> %{
  name: x.exercise.name,
  id: x.exercise.id,
  date: x.workout.date,
  weight: x.weight,
  set: x.set,
  reps: x.reps,
  rir: x.rir

}
end)|> Enum.group_by(fn w-> w.name end)
IO.inspect(workout)


series = Enum.map(workout, fn {name, records}->
  %{
    name: name,
    date: Enum.map(records, fn r-> %{
      x: Date.to_string(r.date),
      y: r.weight

    } end)
  }

end)


chart =
  LiveCharts.build(%{
    type: :line,
   series: series,
    options: %{
      xaxis: %{type: "datetime", title: %{text: "Date"}},
      yaxis: %{title: %{text: "Weight (kg)"}},
      stroke: %{curve: "smooth"}
    }
  })
  IO.inspect(chart)



  {:ok, assign(socket, chart: chart, filterApplied: "All", workout: workout, exercises: exercises, allExercises: exercises, exerciseSelected: exerciseSelected, client_id: id)}

end
 def render(assigns) do
 ~H"""


 <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
    <!-- Filter By Type -->
    <div>
      <h3 class="text-sm font-medium text-gray-700 mb-3 flex items-center">
        <svg class="w-4 h-4 mr-2 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z"></path>
        </svg>
        Filter By Type
      </h3>

      Applied {@filterApplied}
      <div class="flex flex-wrap gap-2">
        <.button
        phx-click="filterByType"
        phx-value-name="ALL"
          class={[
            "px-4 py-2 rounded-md text-sm font-medium transition-all duration-200",
            if(@filterApplied == "ALL",
              do: "bg-blue-600 text-white shadow-md",
              else: "bg-gray-100 hover:bg-gray-200 text-gray-700 hover:shadow-sm"
            )
          ]}
        >
          All Types
        </.button>

        <.button
        phx-click="filterByType"
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
        phx-click="filterByType"
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
        phx-click="filterByType"
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
        phx-click="filterByType"
        phx-value-name="Biceps"
          class={[
            "px-4 py-2 rounded-md text-sm font-medium transition-all duration-200",
            if(@filterApplied == "Bicep",
              do: "bg-blue-600 text-white shadow-md",
              else: "bg-gray-100 hover:bg-gray-200 text-gray-700 hover:shadow-sm"
            )
          ]}
        >
          Biceps
        </.button>

        <.button
        phx-click="filterByType"
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
        phx-click="filterByType"
        phx-value-name="Hamstrings"
          class={[
            "px-4 py-2 rounded-md text-sm font-medium transition-all duration-200",
            if(@filterApplied == "Quads",
              do: "bg-blue-600 text-white shadow-md",
              else: "bg-gray-100 hover:bg-gray-200 text-gray-700 hover:shadow-sm"
            )
          ]}
        >
          Hamstrings
        </.button>

        <.button
          phx-click="filterByType"
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
    </div>

    <div class="grid grid-cols-2 lg:grid-cols-2 gap-8">
          <!-- Exercise Library Section -->
          <div class="bg-white rounded-xl shadow p-6 border">
            <div class="flex items-center justify-between mb-4">
              <h2 class="text-xl font-semibold text-gray-800">Exercise Library</h2>
              <span class="text-sm text-gray-500">
                <%= length(@exercises) %> available
              </span>
            </div>

            <div class="divide-y divide-gray-200 max-h-96 overflow-y-auto">
              <%= for exercise <- @exercises do %>
                <button
                  phx-click="changeExercise"
                  phx-value-id={exercise.id}
                  class="w-full flex items-center justify-between px-4 py-3 text-left hover:bg-gray-100 transition"
                >
                  <span class="font-medium text-gray-800"><%= exercise.name %></span>
                  <span class="text-green-600 font-bold text-lg">+</span>
                </button>
              <% end %>
            </div>
          </div>
          <ul class="space-y-6">



  <%= for {name, workouts} <- @workout do %>


    <li class="border p-4 rounded-lg shadow-sm">
      <h2 class="text-lg font-semibold text-blue-500"><%= name %></h2>

      <ul class="ml-4 mt-3 space-y-2">

        <%= for set <- workouts do %>

          <li class="text-black">
            <p class="font-bold text--200">Date: <%= set.date %></p>
            <p>Set <%= set.set %>:
              <strong><%= set.weight %> kg × <%= set.reps %> reps</strong>
              <span class="text-sm text-black">(RIR: <%= set.rir %>)</span>
            </p>
          </li>
        <% end %>

      </ul>
    </li>
  <% end %>
</ul>




          </div>






 <%= if map_size(@workout) == 0 do %>
  No Record for the Given Exercise
  <%else%>
  <%end%>







  """

end
end
