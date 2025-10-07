defmodule CrohnjobsWeb.WorkoutDetail do
alias Crohnjobs.Programmes
alias Crohnjobs.Programmes.ProgrammeUser

alias Crohnjobs.Fitness
alias Crohnjobs.Fitness.WorkoutDetail
alias Crohnjobs.Repo
alias Crohnjobs.Trainers
alias Crohnjobs.CustomExercises.CustomExercise
alias Crohnjobs.Exercise
import Ecto.Query
  use CrohnjobsWeb, :live_view



  def handle_event("deleteAllExercise", _, socket) do
    Repo.delete_all(from w in WorkoutDetail, where: w.workout_id == ^socket.assigns.workout_id)
    {:noreply,socket|>put_flash(:info, "All Exercises Deleted")|> assign(myWorkout: [])}


  end

  def handle_event("addProgramme", params, socket) do

    template_id = String.to_integer(params["id"])

    template = socket.assigns.programme.programme.programmeTemplates|> Enum.find(&(&1.id == template_id))
    IO.inspect(template)
    Repo.delete_all(
      from w in WorkoutDetail,
      where: w.workout_id == ^socket.assigns.workout_id
    )
newExercises = Enum.map(template.programmeDetails, fn detail->
  {:ok, workout_detail}=
    Crohnjobs.Fitness.create_workout_detail(%{
      workout_id: socket.assigns.workout_id,
      exercise_id: detail.exercise.id,
      set: 1,
      reps: 0,
      rir: 0,
      weight: 0

    })
    workout_detail = Crohnjobs.Repo.preload(workout_detail, :exercise)
    %{
      exercise_id: detail.exercise_id,
      exercise: workout_detail.exercise,
      sets: [
        workout_detail|> Crohnjobs.Fitness.change_workout_detaial()|>to_form()
      ]
    }

end)


    IO.inspect(newExercises, label: "✅ New Exercises (formatted)")
    {:noreply, assign(socket, myWorkout: newExercises)}
  end

  def handle_event("filterExercise", %{"name" => name}, socket) do
    filtered_exercises =
      case name do
        "All" -> socket.assigns.allExercises
        _ -> Enum.filter(socket.assigns.allExercises, &(&1.type == name))
      end

    {:noreply,
     assign(socket,
       exercises: filtered_exercises,
       filterApplied: name
     )}
  end

  def handle_event("addExercise", params, socket) do
    id = String.to_integer(params["id"])

    case Enum.find(socket.assigns.myWorkout, &(&1.exercise_id == id))do
    nil ->  {:ok, workout_detail} = Fitness.create_workout_detail(%{workout_id: socket.assigns.workout_id, exercise_id: id, set: 1, reps: 0, weight: 0, rir: 0 })
    workout_detail = Repo.preload(workout_detail, :exercise)
    form = Fitness.change_workout_detaial(workout_detail)|> to_form()
    new_my_workout = [
      %{exercise_id: id, exercise: workout_detail.exercise, sets: [form]} | socket.assigns.myWorkout
    ]

    {:noreply, assign(socket, myWorkout: new_my_workout)}
    _ -> exercises = (Enum.find(socket.assigns.myWorkout, &(&1.exercise_id == id)))
    sets = length(exercises.sets)
    {:ok, workout_detail} = Fitness.create_workout_detail(%{
      workout_id: socket.assigns.workout_id, exercise_id: id, set: sets+1, reps: 0, weight: 0
    })
    workout_detail = Repo.preload(workout_detail, :exercise)
    form = Fitness.change_workout_detaial(workout_detail)|> to_form()
    my_workout = Enum.map(socket.assigns.myWorkout, fn x-> if x.exercise_id == id do
      %{x|sets: x.sets ++[form]}
    else
      x


    end


    end)
    IO.inspect(my_workout)
    {:noreply, assign(socket, myWorkout: my_workout )}




    end


  end



def handle_event("removeSet", params, socket) do
  workout_id = String.to_integer(params["workout_detail"]["id"])
  workoutDetail = Fitness.get_workout_detail!(workout_id)
  exercise_id = String.to_integer(params["exercise"])
  case Fitness.delete_workout_detaial(workoutDetail) do
    {:ok, _workout}->
      new_myWorkout = Enum.map(socket.assigns.myWorkout, fn x-> if x.exercise_id == exercise_id do
        %{x | sets: Enum.reject(x.sets, fn set_form-> set_form.data.id == workout_id end)}
      else
        x

      end


      end)|> Enum.reject(fn exercise-> Enum.empty?(exercise.sets)end)
      {:noreply, assign(socket, myWorkout: new_myWorkout)}
      _ ->{:noreply, socket|>put_flash(:error, "SOmething happened")}

  end

end






def handle_event("updateExercise", params, socket) do
 exercise_id = String.to_integer(params["exercise"])
  workout_id = String.to_integer(params["workout_detail"]["id"])

  weight =
    case params["workout_detail"]["weight"] do
      "" -> 0.0
      w ->
        case Float.parse(w) do
          {f, _} -> f
          :error -> 0.0
        end
    end
    reps =
      case params["workout_detail"]["reps"] do
        "" -> 0
        w -> String.to_integer(w)
      end

      rir =
        case params["workout_detail"]["rir"] do
          "" -> 0
          w-> String.to_integer(w)
        end

  workout = Fitness.get_workout_detail!(workout_id)|>Repo.preload(:exercise)
  case Fitness.update_workout_detaial(workout, %{ weight: weight, reps: reps, rir: rir }) do
    {:ok, workoutUpdated} ->
      IO.inspect(workoutUpdated)
      new_myWorkout= Enum.map(socket.assigns.myWorkout, fn x-> if x.exercise_id == exercise_id do
      updated_set = Enum.map(x.sets, fn set_form-> if set_form.data.id == workout_id do
        Fitness.change_workout_detaial(workoutUpdated)|>to_form()
      else
        set_form
      end
    end
        )

        %{x | sets: updated_set}
  else
    x
      end

      end)
      IO.inspect(new_myWorkout)


      {:noreply, socket|> put_flash(:info, "Updated")|> assign(myWorkout: new_myWorkout)}
      _ ->{:noreply, socket|>put_flash(:error, "Something Happened")}
  end

end

  def mount(params, session, socket) do
    workout_id = String.to_integer(params["workout_id"])
    user = socket.assigns.current_user
    id = String.to_integer(params["id"])
    programme = Repo.get_by(ProgrammeUser, %{client_id: id, is_active: true})|> Repo.preload(programme: [programmeTemplates: [programmeDetails: [:exercise]]])


    trainer = Trainers.get_trainer_byUserId(user.id)
    customExercises = Repo.all(from c in CustomExercise, where: c.trainer_id == ^trainer.id)
    exercises = Exercise.list_exercises()++ customExercises
    workoutDetails = Repo.all(from w in WorkoutDetail, where: w.workout_id == ^workout_id)|>Repo.preload(:exercise)
    grouped =
      workoutDetails
      |> Enum.group_by(& &1.exercise_id)
      |> Enum.map(fn {exercise_id, details} ->
        %{
          exercise_id: exercise_id,
          exercise: details |> List.first() |> Map.get(:exercise),
          sets: Enum.map(details, fn detail ->
            # build changeset + form for each set
            detail
            |> Crohnjobs.Fitness.WorkoutDetail.changeset(%{})
            |> Phoenix.Component.to_form()
          end)
        }
      end)

      IO.inspect(grouped)


    changesets = Enum.map(workoutDetails, fn workout-> workout|> Fitness.change_workout_detaial()|>to_form()end)




    {:ok, assign(socket, programme: programme, workout_id: workout_id, workoutDetails:  changesets, myWorkout: grouped, exercises: exercises, allExercises: exercises, filterApplied: "All")}

  end
  def render(assigns) do
    ~H"""
    <div class="p-6 space-y-8 bg-gray-50 min-h-screen">

      <!-- Header -->
      <div class="flex items-center justify-between">
        <h1 class="text-2xl font-bold text-gray-900">Workout Builder</h1>

        <%= if length(@myWorkout) > 0 do %>
          <.button
            data-confirm="This will delete all Exercises"
            phx-click="deleteAllExercise"
            class="bg-red-500 hover:bg-red-600 text-white font-medium px-4 py-2 rounded-lg shadow-sm transition-all"
          >
            Delete All Exercises
          </.button>
        <% end %>
      </div>


      <%= if @programme != nil do%>
      <!-- Programme Section -->
      <div class="bg-white rounded-xl shadow p-6 border border-gray-100">
        <h2 class="text-lg font-semibold text-gray-900 mb-4 flex items-center">
          <svg class="w-5 h-5 mr-2 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-3-3v6m9-6a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>

          Programme: <span class="ml-2 text-gray-600 font-normal"><%= @programme.programme.name %></span>
        </h2>

        <ul class="space-y-3">
          <%= for programme <- @programme.programme.programmeTemplates do %>
            <li class="flex items-center justify-between p-3 bg-gray-50 hover:bg-gray-100 rounded-lg transition">
              <div>
                <span class="font-medium text-gray-800"><%= programme.name %></span>
              </div>

              <.button
                phx-value-id={programme.id}
                data-confirm="This will clear your current workout and replicate it with a programme"
                phx-click="addProgramme"
                class="bg-blue-600 hover:bg-blue-700 text-white text-sm font-medium px-3 py-1.5 rounded-md shadow-sm transition"
              >
                Load Programme
              </.button>
            </li>
          <% end %>
        </ul>
      </div>
      <%else%>
      No Programme Enrolled
      <%end%>

      <!-- Exercise Filter Section -->
      <div class="bg-white rounded-xl shadow p-6 border border-gray-100">
        <div class="flex items-center justify-between mb-4">
          <h2 class="text-lg font-semibold text-gray-900">Filter Exercises</h2>

          <%= if @filterApplied != "All" do %>
            <.button
              phx-click="filterExercise"
              phx-value-name="All"
              class="text-sm bg-gray-100 hover:bg-gray-200 text-gray-700 px-3 py-1 rounded-md transition-colors"
            >
              Clear Filters
            </.button>
          <% end %>
        </div>

        <div class="flex flex-wrap gap-2">
          <%= for type <- ["All", "Chest", "Back", "Abs", "Biceps", "Triceps", "Quads", "Hamstrings", "Glutes", "Shoulders"] do %>
            <.button
              phx-click="filterExercise"
              phx-value-name={type}
              class={[
                "px-3 py-2 rounded-md text-sm font-medium transition-all duration-200",
                if(@filterApplied == type,
                  do: "bg-blue-600 text-white shadow-sm",
                  else: "bg-gray-100 hover:bg-gray-200 text-gray-700"
                )
              ]}
            >
              <%= type %>
            </.button>
          <% end %>
        </div>
      </div>

      <!-- Exercise List -->
      <div class="bg-white rounded-xl shadow p-6 border border-gray-100">
        <h2 class="text-lg font-semibold text-gray-900 mb-3">Exercises</h2>

        <div class="divide-y divide-gray-200 max-h-[400px] overflow-y-auto rounded-lg border border-gray-100">
          <%= for exercise <- @exercises do %>
            <button
              phx-click="addExercise"
              phx-value-id={exercise.id}
              class="w-full flex items-center justify-between px-4 py-3 hover:bg-gray-50 transition"
            >
              <span class="font-medium text-gray-800"><%= exercise.name %></span>
              <span class="text-green-600 font-bold text-xl">+</span>
            </button>
          <% end %>
        </div>
      </div>

      <!-- Current Workout Section -->
      <%= if length(@myWorkout) > 0 do %>
        <div class="bg-white rounded-xl shadow p-6 border border-gray-100">
          <h2 class="text-lg font-semibold text-gray-900 mb-4">Your Current Workout</h2>

          <div class="space-y-8">
            <%= for exercise <- @myWorkout do %>
              <div class="border border-gray-200 rounded-lg p-4 shadow-sm hover:shadow-md transition">
                <div class="flex items-center justify-between mb-3">
                  <h3 class="font-semibold text-gray-900"><%= exercise.exercise.name %></h3>

                  <.button
                    phx-click="addExercise"
                    phx-value-id={exercise.exercise.id}
                    class="bg-green-500 hover:bg-green-600 text-white text-xs font-medium px-2.5 py-1 rounded-md"
                  >
                    + Add Set
                  </.button>
                </div>

                <div class="space-y-3">
                  <%= for set <- exercise.sets do %>
                    <div class="bg-gray-50 p-3 rounded-md flex flex-col md:flex-row md:items-end md:space-x-3 border border-gray-200">
                      <.form  for={set}  phx-submit="updateExercise" class="flex-1 grid grid-cols-2 md:grid-cols-4 gap-3">
                        <.input type="hidden" name="exercise" value={exercise.exercise_id} field={exercise.exercise_id}/>
                        <.input type="hidden" field={set[:id]}/>

                        <.input label="Weight (kg)" field={set[:weight]} type="number" class="w-full" />
                        <.input label="Reps" field={set[:reps]} type="number" class="w-full" />
                        <.input label="RIR" field={set[:rir]} type="number" class="w-full" />

                        <div class="flex justify-end col-span-2 md:col-span-1">
                          <.button class="bg-blue-600 hover:bg-blue-700 text-white text-sm px-3 py-2 rounded-md w-full md:w-auto">
                            Update
                          </.button>
                        </div>
                      </.form>

                      <.form  for={set} phx-submit="removeSet" class="mt-2 md:mt-0">
                        <.input type="hidden" field={set[:id]}/>
                        <.input type="hidden" name="exercise" value={exercise.exercise_id} field={exercise.exercise_id}/>
                        <.button class="text-red-600 hover:text-red-700 text-sm underline">
                          Remove Set
                        </.button>
                      </.form>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>

    </div>
    """
  end

end
