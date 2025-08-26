defmodule CrohnjobsWeb.TemplateDetail do

  use CrohnjobsWeb, :live_view
  alias Crohnjobs.Programmes.ProgrammeDetails
  alias Crohnjobs.Repo
  alias Crohnjobs.Exercise
  alias Crohnjobs.Programmes
  import Ecto.Query

  def handle_event("addExercise", params, socket) do
   exercise_id = String.to_integer(params["id"])
   programmeDetails = socket.assigns.programmeDetails
   exerciseFound = Enum.find(programmeDetails, fn x-> x.data.exercise_id == exercise_id end)
  case exerciseFound do
    nil ->
      newDetail = %{exercise_id: exercise_id, reps: "10", set: "1", programme_template_id: socket.assigns.template_id }
      case Programmes.create_programme_details(newDetail) do
        {:ok, programme}->
          programmeDetail = Programmes.get_programme_detail_with_exericse!(programme.id)
        form = Programmes.change_programme_details(programmeDetail) |> to_form()
          programmeDetails = programmeDetails ++ [form]
              {:noreply, assign(socket, programmeDetails: programmeDetails)}

      end
      _ -> {:noreply, socket}

  end


  end
  def handle_event("deleteExercise", params, socket) do
    id = String.to_integer(params["id"])
    programmeDetails = socket.assigns.programmeDetails|> Enum.reject( fn x-> x.data.id == id end)

    {:noreply, assign(socket,template_id: socket.assigns.template_id, programmeDetails: programmeDetails, exercises: socket.assigns.exercises)}

  end

  def handle_event("updateForm", params, socket) do
    id = String.to_integer(params["programme_details"]["id"])
    reps = params["programme_details"]["reps"]
    set = params["programme_details"]["set"]
    programmeDetails = socket.assigns.programmeDetails
    programmeToUpdate = Enum.map(programmeDetails, fn x-> if x.data.id == id do
     updatedData =  %{x.data| set: set, reps: reps}
     Programmes.change_programme_details(updatedData)|> to_form()
    else
      x
    end
    end )
    {:noreply, assign(socket,template_id: socket.assigns.template_id, programmeDetails: programmeToUpdate, exercises: socket.assigns.exercises)}

  end

  def mount(params, session, socket) do



    template_id = params["template_id"]
    exercises = Exercise.list_exercises()

    programmeTemplate =
      Repo.all(
        from pd in ProgrammeDetails,
          where: pd.programme_template_id == ^template_id,
          preload: [:exercise]
      )
      changesets = Enum.map(programmeTemplate, fn template-> template|> Programmes.change_programme_details()|> to_form() end)

      {:ok, assign(socket, template_id: template_id, programmeDetails: changesets, exercises: exercises)}

  end



  def render(assigns) do
    ~H"""

<div class="grid grid-cols-2">
<div class="border">
<ul>

    <%=for exercise <-@exercises do %>
    <li> <.button phx-click="addExercise" phx-value-id={exercise.id}>
        <%= exercise.name %>
        </.button>

     </li>
    <%end%>
    </ul>
    </div>



<div>

<%= for template <-@programmeDetails do %>

<.button phx-click="deleteExercise"  phx-value-id={template.data.id}>
Delete
</.button>
<.form phx-submit="updateForm" for={template}>

<.input type="hidden" field={template[:id]}/>
<label>
{template.data.exercise.name}
</label>
<label>
Set
</label>
<.input label="set" field={template[:set]}/>
<.input label="reps" field={template[:reps]}/>
<.button>
Update
</.button>
</.form>


<%end%>

</div>

    </div>
    """

  end

end
