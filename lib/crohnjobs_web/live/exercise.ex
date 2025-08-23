defmodule CrohnjobsWeb.Exercise do
  use CrohnjobsWeb, :live_view

  @impl true
  alias Crohnjobs.Workout

  def mount(_params, _session, socket) do

    name_form = to_form(%{"name"=>"Ebrahim"})
    update_set_form = to_form(%{
      exercises: [
        %{
          id: 1,
          exercise_id: 1,
          name: "Bench Press",
          workout: [
            %{set: 1, reps: 1, weight: 1}
          ]
        }
      ]
    })




    workout = Enum.sort_by(Workout.list_exercises(), & &1.name)

    {:ok, assign(  socket,   %{  update_set_form: update_set_form,    name_form: name_form ,report: "",  date: Date.utc_today(),  exercises: [%{ id: 1, exercise_id: 1,  name: "Bench Press", workout: [%{set: 1, reps: 1, weight: 1}]},



    ],
    databaseExercises: Enum.map(workout, fn x->{x.name, x.id} end)

  }
    )}
  end



def handle_event("removeSet", %{"name"=> name},socket) do

 [_fieldValue, exerciseId, setId] = String.split(name, "_")
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
  name_form = to_form(%{"name"=>name})

{:noreply, assign(socket, name_form: name_form)}

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
  def handle_event("reset", _unsigned_params, socket) do
    {:noreply, assign(socket, exercises: [])|> put_flash(:info, "All Exercises Has been Reset")}

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
  @impl true
def handle_event("submit", _unsigned_params, socket) do
  Crohnjobs.WorkoutTracker.programme(%{name: socket.assigns.name, date: socket.assigns.date, exercises: socket.assigns.exercises})

   {:noreply, assign(socket, report: "true")|> put_flash(:info, "Workout Added. You can press download to view in on your device")}

end

@impl true
  def handle_event("add", _unsigned_params, socket) do
    newExercise = %{ id: length(socket.assigns.exercises)+1, exercise_id: 1,  name: "Bench Press", workout: [%{set: 1, reps: 1, weight: 1}]}
    updatedExercises = socket.assigns.exercises ++ [newExercise]

    {:noreply, assign(socket, exercises: updatedExercises)}

  end

  @impl true
  @spec render(any()) :: Phoenix.LiveView.Rendered.t()


  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-slate-50 to-gray-100 py-6">
      <div class="max-w-4xl mx-auto p-6 space-y-8">
        <!-- Header Section -->
        <div class="bg-white rounded-2xl shadow-xl border border-gray-100 p-6">
          <div class="flex items-center justify-between">
            <div class="flex items-center  space-x-3">

              <h1 class="text-3xl  font-bold bg-gradient-to-r from-gray-800 to-gray-600 bg-clip-text text-transparent">
                Workout Builder
              </h1>
            </div>
            <%= if @report == "true" do %>
              <a class="bg-gradient-to-r from-emerald-500 to-emerald-600 hover:from-emerald-600 hover:to-emerald-700 text-white px-6 py-3 rounded-xl shadow-lg hover:shadow-xl transition-all duration-200 flex items-center space-x-2 font-semibold" href="download/workout">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0l-3-3m3 3l3-3M3 17V7a2 2 0 012-2h6l2 2h6a2 2 0 012 2v10a2 2 0 01-2 2H5a2 2 0 01-2-2z"/>
                </svg>
                <span>Download</span>
              </a>
            <% end %>
          </div>
        </div>

        <!-- Workout Details Section -->
        <div class="bg-white rounded-2xl shadow-xl border border-gray-100 p-6 space-y-6">
          <h2 class="text-xl font-bold text-gray-800 border-b border-gray-200 pb-3">Workout Details</h2>


          <div class="grid md:grid-cols-2 gap-6">
            <.form for={@name_form}  phx-change="updateName" class="space-y-2">
              <label class="block text-sm font-semibold text-gray-700"> Name</label>
              <.input
              field={@name_form[:name]}
                name="name"
                placeholder="Enter your name"
                class="w-full px-4 py-3 border border-gray-200 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-200"
              />
            </.form>

            <form  phx-change="dateChange" class="space-y-2">
              <label class="block text-sm font-semibold text-gray-700">Workout Date</label>
              <.input
                type="date"
                name="date"
                value={@date}
                class="w-full px-4 py-3 border border-gray-200 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-200"
              />
            </form>
          </div>

          <div class="grid grid-cols-2 space-x-3">
          <div class="pt-4">
            <.button class="bg-gradient-to-r from-blue-600 to-blue-700 hover:from-blue-700 hover:to-blue-800 text-white px-6 py-3 rounded-xl shadow-lg hover:shadow-xl transition-all duration-200 flex items-center space-x-2 font-semibold" phx-click="add">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"/>
              </svg>
              <span>Add Exercise</span>
            </.button>
          </div>
          <div class="pt-4">
        <.button class="bg-gradient-to-r from-red-500 to-red-600 hover:from-red-500 hover:to-red-600 text-white px-6 py-3 rounded-xl shadow-lg hover:shadow-xl transition-all duration-200 flex items-center space-x-2 font-semibold" phx-click="reset">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>
                        </svg>
              <span>Reset Exercise</span>
            </.button>
        </div>
        </div>

        </div>

        <!-- Exercises Section -->
        <div class="space-y-4">
          <div class="flex items-center space-x-3">
            <h2 class="text-2xl font-bold text-gray-800">Exercises</h2>
            <div class="h-px bg-gradient-to-r from-gray-300 to-transparent flex-1"></div>
          </div>

          <.form for={@update_set_form}  phx-change="updateSet">
            <%= for {exercise, index} <- Enum.with_index(@exercises) do %>
              <div class="bg-white rounded-2xl shadow-xl border border-gray-100 overflow-hidden">
                <!-- Exercise Header -->
                <div class="bg-gradient-to-r from-gray-50 to-gray-100 p-6 border-b border-gray-200">
                  <div class="flex items-center justify-between">
                    <div class="flex items-center space-x-3">
                      <div class="w-8 h-8 bg-gradient-to-r from-indigo-500 to-purple-500 rounded-lg flex items-center justify-center">
                        <span class="text-white font-bold text-sm"><%= index + 1 %></span>
                      </div>
                      <h3 class="text-lg font-semibold text-gray-800">Exercise <%= index + 1 %></h3>
                    </div>
                    <div class="flex items-center space-x-3">
                      <.button
                        class="bg-gradient-to-r from-emerald-500 to-emerald-600 hover:from-emerald-600 hover:to-emerald-700 text-white px-4 py-2 rounded-lg shadow-md hover:shadow-lg transition-all duration-200 flex items-center space-x-2 font-medium"
                        phx-value-id={exercise.id}
                        phx-click="addSet"
                        type="button"
                      >
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"/>
                        </svg>
                        <span>Add Set</span>
                      </.button>
                      <.button
                        class="bg-gradient-to-r from-red-500 to-red-600 hover:from-red-600 hover:to-red-700 text-white px-4 py-2 rounded-lg shadow-md hover:shadow-lg transition-all duration-200 flex items-center space-x-2 font-medium"
                        phx-value-id={exercise.id}
                        phx-click="removeExercise"
                        type="button"
                      >
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>
                        </svg>
                        <span>Remove</span>
                      </.button>
                    </div>
                  </div>

                  <!-- Exercise Selector -->
                  <div class="mt-4">
                    <label class="block text-sm font-semibold text-gray-700 mb-2">Exercise Type</label>
                    <.input
                      type="select"
                      name={"databaseExercise_#{exercise.id}"}
                      value={exercise.exercise_id}
                      options={@databaseExercises}
                      class="w-full px-4 py-3 border border-gray-200 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-200 bg-white"
                    />
                  </div>
                </div>

                <!-- Sets Grid -->
                <div class="p-6">
                  <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                    <%= for workout <- exercise.workout do %>
                      <div class="bg-gradient-to-br from-gray-50 to-gray-100 border-2 border-gray-200 rounded-xl p-4 space-y-4 hover:shadow-md transition-all duration-200">
                        <div class="flex items-center justify-between">
                          <div class="flex items-center space-x-2">
                            <div class="w-6 h-6 bg-gradient-to-r from-blue-500 to-indigo-500 rounded-full flex items-center justify-center">
                              <span class="text-white font-bold text-xs"><%= workout.set %></span>
                            </div>
                            <span class="text-sm font-semibold text-gray-700">Set <%= workout.set %></span>
                          </div>
                        </div>

                        <div class="space-y-3">
                          <div>
                            <label class="block text-xs font-medium text-gray-600 mb-1">Reps</label>
                            <.input
                              type="number"
                              name={"reps_#{exercise.id}_#{workout.set}"}
                              value={workout.reps}
                              class="w-full px-3 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-200 text-center font-semibold"
                            />
                          </div>

                          <div>
                            <label class="block text-xs font-medium text-gray-600 mb-1">Weight (lbs)</label>
                            <.input
                              type="number"
                              name={"weight_#{exercise.id}_#{workout.set}"}
                              value={workout.weight}
                              class="w-full px-3 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-200 text-center font-semibold"
                            />
                          </div>
                        </div>

                        <div class="pt-2 border-t border-gray-200">
                          <.button
                            type="button"
                            phx-click="removeSet"
                            phx-value-name={"set_#{exercise.id}_#{workout.set}"}
                            class="w-full text-red-600 hover:text-red-700 hover:bg-red-50 px-3 py-2 rounded-lg text-sm font-medium transition-all duration-200 flex items-center justify-center space-x-2"
                          >
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>
                            </svg>
                            <span>Remove Set</span>
                          </.button>
                        </div>
                      </div>
                    <% end %>
                  </div>
                </div>
              </div>
            <% end %>

            <!-- Submit Section -->
            <div class="bg-white rounded-2xl shadow-xl border border-gray-100 p-6">
              <div class="text-center">
                <.button
                  type="button"
                  class="bg-gradient-to-r from-blue-700 to-indigo-700 hover:from-blue-800 hover:to-indigo-800 text-white px-8 py-4 rounded-xl shadow-lg hover:shadow-xl transition-all duration-200 flex items-center justify-center space-x-3 font-bold text-lg mx-auto"
                  phx-click="submit"
                >
                  <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z"/>
                  </svg>
                  <span>Complete Workout</span>
                </.button>
              </div>
            </div>
          </.form>
        </div>
      </div>
    </div>
    """
  end

end
