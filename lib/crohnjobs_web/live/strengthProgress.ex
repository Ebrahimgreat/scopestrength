defmodule CrohnjobsWeb.StrengthProgress do
  use CrohnjobsWeb, :live_view

  import Ecto.Query
  alias Crohnjobs.Exercises.Exercise
  alias Crohnjobs.Trainers
  alias Crohnjobs.Clients
  alias Crohnjobs.Repo

  def mount(params, _session, socket) do
    user = socket.assigns.current_user
    trainer = Trainers.get_trainer_byUserId(user.id)
    id = String.to_integer(params["id"])

    case Repo.get(Clients.Client, id) |> Repo.preload(:user) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Client Not found")
         |> push_navigate(to: "/trainer/clients")}

      client ->
        case client.trainer_id == trainer.id do
          true ->
            exercises =
              Repo.all(
                from e in Exercise,
                  where: e.is_custom == false or e.user_id == ^user.id,
                  order_by: [asc: e.name],
                  preload: [:muscle, :equipment]
              )

            {:ok, assign(socket, exercises: exercises, client_id: id)}

          false ->
            {:ok,
             socket
             |> put_flash(:error, "Client Does not exist")
             |> push_navigate(to: "/trainer/clients")}
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

            <h1 class="text-3xl lg:text-4xl font-semibold tracking-tight text-slate-900">              Strength Progress</h1>
            <p class="mt-2 text-slate-600 text-base lg:text-lg">
                Track your strength gains and monitor exercise progress.
              </p>
            </div>
          </div>
        </div>
      </div>

      <div class="max-w-6xl mx-auto px-6 py-8 space-y-6">
        <div class="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
          <%= if length(@exercises) > 0 do %>
            <div class="overflow-x-auto">
              <table class="w-full text-sm">
                <thead class="bg-slate-50 border-b border-slate-200">
                  <tr>
                    <th class="text-left py-3 px-6 font-semibold text-slate-800">Exercise</th>
                    <th class="text-left py-3 px-6 font-semibold text-slate-800">Type</th>
                    <th class="text-left py-3 px-6 font-semibold text-slate-800">Equipment</th>
                    <th class="text-left py-3 px-6 font-semibold text-slate-800">Source</th>
                    <th class="text-left py-3 px-6 font-semibold text-slate-800"> View</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-slate-200">
                  <%= for exercise <- @exercises do %>
                    <tr class="hover:bg-slate-50 transition">
                      <td class="py-4 px-6">
                        <div class="font-semibold text-slate-900">{exercise.name}</div>
                      </td>
                      <td class="py-4 px-6">
                        <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold bg-emerald-50 text-emerald-700 border border-emerald-100">
                          {if exercise.muscle, do: exercise.muscle.name, else: "N/A"}
                        </span>
                      </td>
                      <td class="py-4 px-6 text-slate-700">
                        {if exercise.equipment, do: exercise.equipment.name, else: "None"}
                      </td>
                      <td class="py-4 px-6">
                        <span class={[
                          "inline-flex items-center gap-2 text-xs font-semibold px-2.5 py-1 rounded-full border",
                          if(exercise.is_custom,
                            do: "bg-amber-50 text-amber-700 border-amber-100",
                            else: "bg-slate-100 text-slate-700 border-slate-200"
                          )
                        ]}>
                          <span class={[
                            "w-2 h-2 rounded-full",
                            if(exercise.is_custom, do: "bg-amber-500", else: "bg-slate-400")
                          ]}>
                          </span>
                          {if exercise.is_custom, do: "Custom", else: "Library"}
                        </span>
                      </td>
                      <td>
                      <.link navigate={~p"/trainer/clients/#{@client_id}/strengthProgress/#{exercise.id}"}>
                      View

                      </.link>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          <% else %>
            <div class="text-center py-12">
              <svg
                class="w-16 h-16 mx-auto text-slate-300 mb-4"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
                />
              </svg>
              <h3 class="text-lg font-semibold text-slate-900 mb-1">No exercises available</h3>
              <p class="text-slate-500">
                Add exercises to start tracking your strength progress.
              </p>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
