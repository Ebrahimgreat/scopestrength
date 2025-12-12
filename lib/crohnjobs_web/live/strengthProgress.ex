defmodule CrohnjobsWeb.StrengthProgress do
alias Crohnjobs.Exercise
alias Crohnjobs.CustomExercises.CustomExercise
alias Crohnjobs.Trainers
import Ecto.Query
alias Crohnjobs.Repo
 use CrohnjobsWeb, :live_view

def mount(_params, session, socket) do
  user = socket.assigns.current_user
  trainer = Trainers.get_trainer!(user.id)


  customExercises = Repo.all(from c in CustomExercise, where: c.trainer_id==^trainer.id)
  exercises = Exercise.list_exercises()++customExercises

  {:ok, assign(socket, exercises: exercises)}
end

  def render(assigns) do
    ~H"""
   <div class="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">

   <table class="w-full">
   <thead class="bg-gray-50 border-b border-gray-200">
   <tr>
   <th class="text-left py-4 px-6 font-semibold text-gray-900"> Exercise</th>
   <th class="text-left py-4 px-6 font-semibold text-gray-900"> Type</th>
   <th class="text-left py-4 px-6 font-semibold text-gray-900"> Equipment</th>
   </tr>
   </thead>
   <tbody class="divide-y divide-gray-200">
   <%=for exercise<-@exercises do %>
   <td class="py-4 px-6 font-medium text-gray-900"><%= exercise.name %></td>
                    <td class="py-4 px-6 text-gray-600"><%= exercise.type || "N/A" %></td>
                    <td class="py-4 px-6 text-gray-600"><%= exercise.equipment || "None" %></td>
                    <%end%>
   </tbody>
   </table>





   </div>
    """
  end


end
