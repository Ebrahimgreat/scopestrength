defmodule CrohnjobsWeb.Workouts do
alias Crohnjobs.Trainers
alias Crohnjobs.Clients
alias Crohnjobs.Repo
  use CrohnjobsWeb, :live_view
  import Ecto.Query

  def mount(params, session, socket) do
    user = socket.assigns.current_user
    trainer = Trainers.get_trainer_byUserId(user.id)
    client_id = String.to_integer(params["id"])
    case Repo.get(Clients.Client,client_id) do
      nil->
        {:ok, socket|>put_flash(:error, "Client Not found")}
    client->
      case client.trainer_id == trainer.id do
        true->
    client = Clients.get_client!(client_id)|>Repo.preload(:user)
    workouts = Repo.all(from w in Crohnjobs.Training.Workout, where: w.client_id == ^client_id)
    {:ok,assign(socket,workouts: workouts, client_id: client_id, client: client)}
    false ->
      {:ok, socket|>put_flash(:error, "Client Does not exist")}
    end
  end

  end

  def render(assigns) do
    ~H"""
   <div class="w-full min-h-screen">
    <div class="w-full px-6 lg:px-10 pt-10 pb-4">
        <div class="max-w-6xl mx-auto px-6 py-8">
          <div class="flex items-start justify-between gap-6">
            <div>

            <h1 class="text-3xl lg:text-4xl font-semibold tracking-tight text-slate-900">  Client Workouts</h1>
            <p class="mt-2 text-slate-600 text-base lg:text-lg">
                Monitor the workouts of  <b> {@client.user.name}</b>
              </p>
            </div>
          </div>
        </div>
      </div>

      <div class="max-w-6xl mx-auto px-6 py-8 space-y-6">
        <div class="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
          <%= if length(@workouts) > 0 do %>
            <div class="overflow-x-auto">
              <table class="w-full text-sm">
                <thead class="bg-slate-50 border-b border-slate-200">
                  <tr>
                    <th class="text-left py-3 px-6 font-semibold text-slate-800">Workout</th>
                    <th class="text-left py-3 px-6 font-semibold text-slate-800">
                    Date</th>

                  </tr>
                </thead>
                <tbody class="divide-y divide-slate-200">
                <%= for workout <- @workouts do %>
                <tr class="hover:bg-slate-50 transition">
                <td class="py-4 px-6">
                <.link navigate={~p"/trainer/clients/#{@client_id}/workouts/#{workout.id}"}>
                {workout.name}
                </.link>
                </td>
                <td class="py-4 px-6">
                {workout.date}
                </td>
                </tr>

                <%end%>


</tbody>
                </table>
                </div>
                <%end%>
                </div>
                </div>



      </div>




    """

  end

end
