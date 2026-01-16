defmodule CrohnjobsWeb.Exercises do


  alias Crohnjobs.Exercises.Exercise
  alias Crohnjobs.CustomExercises
  alias Crohnjobs.Repo
  alias Crohnjobs.Exercise
  import Ecto.Query

alias Crohnjobs.Trainers
alias Crohnjobs.CustomExercises.CustomExercise
  use CrohnjobsWeb, :live_view




  def handle_event("addExercise", params, socket) do

    user = socket.assigns.current_user

    name = params["exercise"]["name"]
    equipment = params["exercise"]["equipment"]
    type = params["exercise"]["type"]

   case Exercise.create_exercise(%{name: name, equipment: equipment, type: type, is_custom: true, user_id: user.id}) do
     {:ok, exercise}->
      exercises = socket.assigns.exercises ++ [exercise]


      {:noreply,socket|> assign(show_modal: false, exercises: exercises)|>put_flash(:info, "New Exercise Created")}
     _ -> {:noreply, socket|> put_flash(:error, "An error has occured")}

   end

  end

  def handle_event("deleteExercise", params, socket) do
    user = socket.assigns.current_user

    id = String.to_integer(params["id"])
    exercise = Exercise.get_exercise!(id)
   case Exercise.delete_exercise(exercise) do
    {:ok, _customExercise }->
      updatedExercise = Enum.reject(socket.assigns.exercises, fn x-> Map.has_key?(x, :user_id) and x.id == id end)
      {:noreply,socket|>put_flash(:info, "Deleted Successfully")|> assign(exercises: updatedExercise)}
      _ ->{:noreply, socket|>put_flash(:error, "Something Happened")}
   end




  end



  def handle_event("openModal", _params, socket) do
    show_modal = !socket.assigns.show_modal
    {:noreply, assign(socket, show_modal: show_modal)}


  end

  def handle_event("editExercise", %{"id"=> id}, socket) do
    showEditExercise =  true
    exercise = Exercise.get_exercise!(id)

    editExerciseFrom = Crohnjobs.Exercise.change_exercise(exercise)|> to_form()
    {:noreply, assign(socket, editExerciseForm: editExerciseFrom, show_edit_exercise: showEditExercise)}
  end


  def handle_event("saveExercise", params, socket) do
   id = String.to_integer(params["exercise"]["id"])
   name = params["exercise"]["name"]
   type = params["exercise"]["type"]
   IO.inspect(id)

   equipment = params["exercise"]["equipment"]
   exercise = Exercise.get_exercise!(id)
   case Exercise.update_exercise(exercise, %{name: name, equipment: equipment, type: type}) do
    {:ok, updated_exercise} ->

      updated_exercises = Enum.map(socket.assigns.exercises, fn x-> if x.id == updated_exercise.id do
        %{x | name: updated_exercise.name, type: updated_exercise.type, equipment: updated_exercise.equipment}
      else
        x
      end
    end)
    {:noreply, socket|>put_flash(:info, "Exercise Updated")|> assign(exercises: updated_exercises) }
      _ ->{:noreply,socket |> put_flash(:info, "Error")}
   end
  end

  def handle_event("closeEditExercise", _, socket) do
    {:noreply, assign(socket, show_edit_exercise: false)}

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


  def handle_event("searching", params, socket) do
    search = params["searchExercise"] || ""

    filtered_exercises =
      if search == "" do
        socket.assigns.exercises
      else
        Enum.filter(socket.assigns.exercises, fn ex ->
          String.contains?(String.downcase(ex.name), String.downcase(search))
        end)
      end

    {:noreply, assign(socket, exercises: filtered_exercises)}
  end


  def mount(_params, _session, socket) do

    user = socket.assigns.current_user

    filterApplied = "All"

    show_modal = false
    show_edit_exercise = false


     newExerciseForm = Crohnjobs.Exercises.Exercise.changeset(%Crohnjobs.Exercises.Exercise{}, %{})|> to_form()
     editExerciseForm = nil



     exercises =
      Repo.all(
        from e in Crohnjobs.Exercises.Exercise,
          where: e.is_custom == false or e.user_id == ^user.id,
          order_by: [asc: e.name]
      )

    {:ok, assign(socket, searchExercise: "", editExerciseForm: editExerciseForm, show_modal: show_modal, show_edit_exercise: show_edit_exercise, newExerciseForm: newExerciseForm, filterApplied: filterApplied, allExercises: exercises, exercises: exercises)}
  end
  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
<div class="min-h-screen bg-zinc-50">
  <!-- Header -->
  <div class="w-full bg-gradient-to-r from-green-600 to-teal-700 text-white px-6 lg:px-10 py-8">
    <h1 class="text-3xl font-bold tracking-tight">Exercise Library</h1>
    <p class="mt-2 text-green-100 text-lg">Browse and manage your exercise collection</p>
  </div>

  <!-- Main Content -->
  <div class="w-full px-6 lg:px-10 py-8">
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6">



<%= if @show_modal do %>
  <div class="fixed inset-0 z-50 flex items-center justify-center">
    <div class="absolute inset-0 bg-black/40" aria-hidden="true"></div>

    <div class="relative bg-white rounded-2xl shadow-xl w-full max-w-lg mx-4 p-6">
      <div class="flex items-start justify-between">
        <div>
          <h2 class="text-xl font-semibold text-gray-900">Create Exercise</h2>
          <p class="text-sm text-gray-500">Add a custom exercise to your library.</p>
        </div>
        <button phx-click="openModal" aria-label="Close" class="text-gray-400 hover:text-gray-600">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
          </svg>
        </button>
      </div>

      <.form phx-submit="addExercise" for={@newExerciseForm} class="mt-4 space-y-4">
        <div class="grid grid-cols-1 gap-4">
          <.input type="text" required label="Exercise name" field={@newExerciseForm[:name]} class="w-full" />

          <div class="grid grid-cols-2 gap-4">
            <.input type="select" options={["Chest","Back","Quads","Hamstrings","Shoulders","Abs","Bicep","Tricep"]} field={@newExerciseForm[:type]} label="Type" />
            <.input type="select" options={["Dumbell","Cable","Barbell","Machine","Plate"]} field={@newExerciseForm[:equipment]} label="Equipment" />
          </div>
        </div>

        <div class="flex items-center justify-end gap-3 pt-2">
          <button type="button" phx-click="openModal" class="px-4 py-2 rounded-md bg-gray-100 text-gray-700 hover:bg-gray-200">Cancel</button>
          <.button class="bg-green-600 hover:bg-green-700 px-4 py-2 rounded-md">Create Exercise</.button>
        </div>
      </.form>
    </div>
  </div>
<% end %>

<button phx-click="openModal" class="bg-green-600 text-white px-4 py-2 rounded">Create Exercise</button>


<.form phx-change="searching">
<.input label="Search Exercise" value={@searchExercise} field={@searchExercise}  name="searchExercise"/>
</.form>



<%= if @show_edit_exercise do %>
  <div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
    <div class="bg-white p-6 rounded-lg w-96 relative">
      <h2 class="text-lg font-semibold mb-4">New Exercise</h2>
      <.form phx-submit="saveExercise" for={@editExerciseForm}>

      <p> Edit the Given Exercise</p>
      <.input type="hidden" field={@editExerciseForm[:id]}/>
      <.input  type="text" required label="name" field={@editExerciseForm[:name]}/>
      <.input type="select" options = {["Chest","Back","Quads","Shoulders","Abs","Bicep","Tricep"]} field={@editExerciseForm[:type]}/>
      <.input type="select" field={@editExerciseForm[:equipment]} options={["Dumbell","Cable","Barbell", "Machine", "Plate"]}/>
      <.button>
      Submit
      </.button>




      <button phx-click="closeEditExercise" class="mt-4 bg-blue-600 text-white px-4 py-2 rounded">Close</button>
      </.form>
    </div>
  </div>
<% end %>

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
                  <th class= "text-left py-4 px-6 font-semibold text-gray-900">
                  </th>
                  <th class= "text-left py-4 px-6 font-semibold text-gray-900">
                  </th>

                </tr>
              </thead>
              <tbody class="divide-y divide-gray-200">
                <%= for exercise <- @exercises do %>
                  <tr class="hover:bg-gray-50 transition-colors duration-150">
                    <td class="py-4 px-6 font-medium text-gray-900"><%= exercise.name %></td>
                    <td class="py-4 px-6 text-gray-600"><%= exercise.type || "N/A" %></td>
                    <td class="py-4 px-6 text-gray-600"><%= exercise.equipment || "None" %></td>
                    <%= if exercise.is_custom == true do %>
                    <td class="py-4 px-6 text-gray-600">

                <.button phx-value-id={exercise.id} phx-click="editExercise">
                Open
                </.button>
                </td>
                <td>
                <.button phx-value-id={exercise.id} phx-click="deleteExercise">
                delete
                </.button>
                </td>



                    <%end%>





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
  </div>
</div>






    """

  end

end
