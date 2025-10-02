defmodule CrohnjobsWeb.WorkoutDetail do
alias Crohnjobs.Fitness
alias Crohnjobs.Fitness.WorkoutDetail
alias Crohnjobs.Repo
alias Crohnjobs.Trainers
alias Crohnjobs.CustomExercises.CustomExercise
alias Crohnjobs.Exercise
import Ecto.Query
  use CrohnjobsWeb, :live_view
  def mount(params, session, socket) do
    workout_id = String.to_integer(params["workout_id"])
    user = socket.assigns.current_user

    trainer = Trainers.get_trainer_byUserId(user.id)
    customExercises = Repo.all(from c in CustomExercise, where: c.trainer_id == ^trainer.id)
    exercises = Exercise.list_exercises()++ customExercises
    workoutDetails = Repo.all(from w in WorkoutDetail, where: w.workout_id == ^workout_id)|>Repo.preload(:exercise)
    changesets = Enum.map(workoutDetails, fn workout-> workout|> Fitness.change_workout_detaial()|>to_form()end)
    IO.inspect(changesets)

    {:ok, assign(socket,workoutDetails: changesets, exercises: exercises)}

  end
  def render(assigns) do
    ~H"""
    <h1> Hello</h1>
    {length(@workoutDetails)}
    <ul>
    <%=for exercise <-@exercises do %>
   <li> <%=exercise.name%>
   </li>
    <%end%>
    </ul>
    <%=for workoutDetail <-@workoutDetails do %>

    <%=workoutDetail.data.exercise.name%>
    <.form for={workoutDetail}>
    <.input label="reps" field={workoutDetail[:reps]}>
    </.input>
    <.input label="set" field={workoutDetail[:set]}>
    </.input>
    <.input label="rir" field={workoutDetail[:rir]}>
    </.input>
    <.button>
    Update
    </.button>
    </.form>
    <%end%>
    """


  end

end
