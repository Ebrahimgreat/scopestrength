defmodule CrohnjobsWeb.Exercise do
alias Postgrex.Extensions.Name
  use CrohnjobsWeb, :live_view

  @impl true
  alias Crohnjobs.Workout
  def mount(_params, _session, socket) do
    workout = Enum.sort_by(Workout.list_exercises(), & &1.name)

    {:ok, assign(  socket,   %{ name: "Ebrahim" ,report: "",  date: Date.utc_today(),  exercises: [%{ id: 1, exercise_id: 1,  name: "Bench Press", workout: [%{set: 1, reps: 1, weight: 1}]},



    ],
    databaseExercises: Enum.map(workout, fn x->{x.name, x.id} end)

  }
    )}
  end



def handle_event("removeSet", %{"name"=> name},socket) do

 [fieldValue, exerciseId, setId] = String.split(name, "_")
 exerciseId = String.to_integer(exerciseId)
 setID = String.to_integer(setId)
 updated_exercises = Enum.map(socket.assigns.exercises, fn item-> if item.id == exerciseId do
   updated_workout = Enum.reject(item.workout, fn set-> set.set == setID
 end
   )
   %{item | workout: updated_workout}
else
  item
end
 end
 )
 IO.inspect(socket.assigns.exercises)
{:noreply, assign(socket, exercises: updated_exercises)}
end
def handle_event("updateName", %{"name"=>name}, socket) do
{:noreply, assign(socket, name: name)}

end




  def handle_event("dateChange", %{"date"=> date}, socket) do
    {:noreply, assign(socket, date: date)}



  end
  def handle_event("removeExercise", %{"id"=>id}, socket) do
    id = String.to_integer(id)
    IO.inspect(id)

    exercises = Enum.reject(socket.assigns.exercises, &(&1.id == id))
    {:noreply, assign(socket, exercises: exercises)}


  end
  def handle_event("updateSet", params, socket) do
    target = List.first(params["_target"])
    if(String.starts_with?(target, "databaseExercise_")) do
   [_, id_str] = String.split(target, "_")
   exerciseId = String.to_integer(id_str)
   workout = Workout.get_exercise!(params["databaseExercise_#{exerciseId}"])

    updated_exercises = Enum.map(socket.assigns.exercises, fn item-> if item.id == exerciseId do
    %{item | name: workout.name, exercise_id: workout.id}
  else
    item
  end
  end
  )
  {:noreply, assign(socket, exercises: updated_exercises)}

else
   [field_type,exercise_id_str,set_str] = String.split(target, "_")
   IO.inspect(field_type)



   id = String.to_integer(exercise_id_str)
   set = String.to_integer(set_str)
   weight = case Integer.parse(params["weight_#{id}_#{set}"] || ""  ) do
    {num,_}-> num
    _ -> 0

   end
   reps = case Integer.parse(params["reps_#{id}_#{set}"] || "") do
     {num,_}-> num
     _ -> 0
   end




    updated_exercises = Enum.map(socket.assigns.exercises, fn item-> if item.id == id  do
      IO.puts("Its a match")
    updated_workout = Enum.map(item.workout, fn workout-> if workout.set == set do
      %{workout | reps: reps, weight: weight}
    else
      workout
    end
  end
       )
       %{item | workout: updated_workout}
  else
    item
    end
    end)
IO.inspect(updated_exercises)

    {:noreply, assign(socket, exercises: updated_exercises)}
  end
end


  def handle_event("addSet", %{"id"=>id}, socket) do
      IO.inspect(id)
      id  = String.to_integer(id)
   updated_exercise = Enum.map(socket.assigns.exercises, fn item-> if item.id == id do
    IO.puts(length(item.workout))
    updated_workout = item.workout ++ [%{set: length(item.workout)+1 , reps: 10, weight: 10}]
    %{item | workout: updated_workout}
   else
    item

   end
  end)
  IO.inspect(updated_exercise)

  {:noreply, assign(socket, exercises: updated_exercise)}

  end

def handle_event("submit", _unsigned_params, socket) do
  Crohnjobs.WorkoutTracker.programme(%{name: socket.assigns.name, date: socket.assigns.date, exercises: socket.assigns.exercises})

   {:noreply, assign(socket, report: "true")|> put_flash(:info, "Workout Added. You can press download to view in on your device")}

end


  def handle_event("add", _unsigned_params, socket) do
    newExercise = %{ id: length(socket.assigns.exercises)+1, exercise_id: 1,  name: "Bench Press", workout: [%{set: 1, reps: 1, weight: 1}]}
    updatedExercises = socket.assigns.exercises ++ [newExercise]

    {:noreply, assign(socket, exercises: updatedExercises)}

  end

  @impl true
  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto p-4 space-y-6">
      <div class="flex items-center justify-between">
        <h1 class="text-2xl font-bold">Workout Builder</h1>
        <%= if @report == "true" do %>
          <a class="bg-red text-black px-4 py-2 rounded shadow" href="download/workout">
            Download
          </a>
        <% end %>
      </div>

      <div class="bg-white border p-4 rounded-lg shadow space-y-4">
        <.form phx-change="updateName">
          <label class="block text-sm font-semibold">Name</label>
          <.input name="name" placeholder="Workout name" value={@name} class="w-full px-2 py-1 border rounded"/>
        </.form>

        <form phx-change="dateChange">
          <label class="block text-sm font-semibold">Date</label>
          <.input type="date" name="date" value={@date} class="w-full px-2 py-1 border rounded"/>
        </form>

        <.button class="bg-blue-600 text-white px-4 py-2 rounded shadow" phx-click="add">
          + Add Exercise
        </.button>
      </div>




      <.form phx-change="updateSet">
        <%= for exercise <- @exercises do %>
          <div class="bg-white border rounded-xl shadow p-4 space-y-4 mb-10">
            <div class="flex items-center justify-between">
              <h2 class="text-lg font-semibold">Exercise</h2>
              <div class="space-x-2">
                <.button class="bg-green-500 text-white px-3 py-1 rounded" phx-value-id={exercise.id} phx-click="addSet" type="button">
                  + Set
                </.button>
                <.button class="bg-red-500 text-white px-3 py-1 rounded" phx-value-id={exercise.id} phx-click="removeExercise" type="button">
                  ✕ Remove
                </.button>
              </div>
            </div>

            <.input
              type="select"
              name={"databaseExercise_#{exercise.id}"}
              value={exercise.exercise_id}
              options={@databaseExercises}
              class="w-full px-2 py-1 border rounded"
            />

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <%= for workout <- exercise.workout do %>
                <div class="border p-3 rounded-lg space-y-2 bg-gray-50">
                  <div class="text-sm font-medium text-gray-700">Set <%= workout.set %></div>

                  <div>
                    <label class="block text-sm font-medium text-gray-700">Reps</label>
                    <.input
                      type="number"
                      name={"reps_#{exercise.id}_#{workout.set}"}
                      value={workout.reps}
                      class="w-full px-2 py-1 border rounded"
                    />
                  </div>

                  <div>
                    <label class="block text-sm font-medium text-gray-700">Weight</label>
                    <.input
                      type="number"
                      name={"weight_#{exercise.id}_#{workout.set}"}
                      value={workout.weight}
                      class="w-full px-2 py-1 border rounded"
                    />
                  </div>

                  <div>
                    <.button
                      type="button"
                      phx-click="removeSet"
                      phx-value-name={"set_#{exercise.id}_#{workout.set}"}
                      class="text-red-600 hover:underline text-sm"
                    >
                      ✕ Remove Set
                    </.button>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>

        <div class="mt-6">
          <.button type="button" class="bg-blue-700 text-white px-6 py-2 rounded-lg hover:bg-blue-800" phx-click="submit">
            Submit Workout
          </.button>
        </div>
      </.form>
    </div>

    """
  end
end
