defmodule CrohnjobsWeb.Exercises do


  alias Crohnjobs.Exercise


  use CrohnjobsWeb, :live_view


  def handle_event("openAddExercise", _, socket) do
    currentDialogOpen = socket.assigns.dialogOpen
    dialogOpen = !currentDialogOpen
    {:noreply, assign(socket, dialogOpen: dialogOpen)}

  end
  def mount(_params, _session, socket) do

    dialogOpen = false
     newExerciseForm = to_form(%{name: "Haka", type: "Boo", equipment: "Hala"})


    exercises = Exercise.list_exercises()
    {:ok, assign(socket, newExerciseForm: newExerciseForm, exercise: exercises, dialogOpen: dialogOpen)}
  end
  def render(assigns) do
    ~H"""
   <.button type="button" phx-click="openAddExercise">
   <%=if @dialogOpen == false do %>
   Add New Exercise
   <% else %>
   Cancel
   <%end%>


   </.button>
    <h1 class="font-bold">
    Exercises
     </h1>


<div class="h-48 overflow-y-auto">
     <table class="border w-full">
  <thead>
    <tr>
      <th class="px-4 py-2">Exercise</th>
      <th class="px-4 py-2">Custom</th>
    </tr>
  </thead>
  <tbody>
    <%= for exercise <- @exercise do %>
      <tr>
        <td class="px-4 py-2"><%= exercise.name %></td>
        <td class="px-4 py-2"><%= exercise.is_custom%> </td>
      </tr>
    <% end %>
  </tbody>
</table>
</div>
    <%= if @dialogOpen ==true do %>
  <.form for={@newExerciseForm}>
  <.input label="name"  id="name" field={@newExerciseForm[:name]} type="text">
  </.input>
  <.input label="equipment"  field={@newExerciseForm[:equipment]} type="text">
  </.input>

  <.input label="name"  field={@newExerciseForm[:target]} type="text">
  </.input>

  <.button>
  Add New Exercise
  </.button>



  </.form>
    <%end%>





    """

  end

end
