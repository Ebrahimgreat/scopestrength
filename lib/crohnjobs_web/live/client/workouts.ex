defmodule CrohnjobsWeb.Client.Workouts do
  alias Crohnjobs.Training
  alias Crohnjobs.Repo
  alias Crohnjobs.Clients.Client
  alias Crohnjobs.Training.Workout
  alias Crohnjobs.Notifications
  import Ecto.Query
  use CrohnjobsWeb, :live_view

  @per_page 12

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    client = Repo.get_by(Client, user_id: user.id)
    workouts = Repo.all(from w in Workout, where: w.client_id == ^client.id, order_by: [desc: w.date])

    {:ok,
     socket
     |> assign(:all_workouts, workouts)
     |> assign(:search, "")
     |> assign(:page, 1)
     |> apply_filters()}
  end

  defp apply_filters(socket) do
    search = socket.assigns.search |> String.downcase()
    all = socket.assigns.all_workouts

    filtered =
      if search == "" do
        all
      else
        Enum.filter(all, fn w ->
          (w.name || "") |> String.downcase() |> String.contains?(search)
        end)
      end

    page = socket.assigns.page
    total_pages = max(ceil(length(filtered) / @per_page), 1)
    page = min(page, total_pages)
    paginated = filtered |> Enum.drop((page - 1) * @per_page) |> Enum.take(@per_page)

    socket
    |> assign(:workouts, paginated)
    |> assign(:filtered_count, length(filtered))
    |> assign(:total_count, length(all))
    |> assign(:page, page)
    |> assign(:total_pages, total_pages)
  end


  def handle_event("search", %{"search" => search}, socket) do
    {:noreply, socket |> assign(:search, search) |> assign(:page, 1) |> apply_filters()}
  end

  def handle_event("page", %{"page" => page}, socket) do
    {:noreply, socket |> assign(:page, String.to_integer(page)) |> apply_filters()}
  end

  def handle_event("createWorkout", _params, socket) do
    user = socket.assigns.current_user
    client = Repo.get_by(Client, user_id: user.id)
    result =
      Repo.transaction(fn ->
        case Training.create_workout(%{
               client_id: client.id,
               name: "Untitled",
               date: DateTime.utc_now()
             }) do
          {:ok, workout} ->
            if client.trainer_id do
              case Notifications.create_notification(%{
                     actor_id: user.id,
                     actor_type: "client",
                     recipient_id: client.trainer_id,
                     recipient_type: "trainer",
                     type: "workout_created",
                     data: %{workout_id: workout.id, client_id: client.id}
                   }) do
                {:ok, notification} -> {workout, notification}
                {:error, changeset} -> Repo.rollback(changeset)
              end
            else
              {workout, nil}
            end

          {:error, changeset} ->
            Repo.rollback(changeset)
        end
      end)

    case result do
      {:ok, {workout, notification}} ->
        if notification do
          Phoenix.PubSub.broadcast(
            Crohnjobs.PubSub,
            "notifications:trainer:#{client.trainer_id}",
            {:notification, notification}
          )
        end

        {:noreply,
         socket
         |> assign(:all_workouts, [workout | socket.assigns.all_workouts])
         |> apply_filters()}

      {:error, _reason} ->
        {:noreply, socket |> put_flash(:error, "Unable To create workout")}
    end
  end
  def handle_event("deleteWorkout", %{"id"=>id}, socket) do
    id= String.to_integer(id)
    workout= Training.get_workout!(id)
    IO.inspect(workout)
    case Training.delete_workout(workout) do
      {:ok, _deleted}->
        all_workouts = Enum.reject(socket.assigns.all_workouts, &(&1.id == id))
        {:noreply, socket |> assign(:all_workouts, all_workouts) |> apply_filters()}
        _->{:noreply,socket|>put_flash(:error, "Cannot delete")}

    end


  end



  def render(assigns) do
    ~H"""
    <div class="min-h-screen">
      <!-- Header Section -->
      <div class="">
        <div class="w-full px-0 sm:px-2 lg:px-4 py-8">
          <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div>
              <h1 class="text-2xl sm:text-3xl font-bold text-gray-900">My Workouts</h1>
              <p class="text-gray-600 mt-1">Track your training progress</p>
            </div>
            <.button phx-click="createWorkout">
            Create Workout
            </.button>
          </div>
        </div>
      </div>

    <!-- Stats Section -->
      <div class="w-full px-0 sm:px-2 lg:px-4 py-8">
        <div class="mb-8">
          <div class="bg-white rounded-2xl shadow-lg p-6 border border-gray-100 hover:shadow-xl transition-shadow duration-300 max-w-sm">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-medium text-gray-600 uppercase tracking-wider">
                  Total Workouts
                </p>
                <p class="text-3xl font-bold text-gray-900 mt-2">{@total_count}</p>
              </div>
              <div class="p-3 bg-emerald-100 rounded-full">
                <svg
                  class="w-8 h-8 text-emerald-600"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4"
                  >
                  </path>
                </svg>
              </div>
            </div>
          </div>
        </div>

        <%= if @workouts == [] do %>
          <div class="text-center py-16">
            <div class="mx-auto w-24 h-24 bg-gray-100 rounded-full flex items-center justify-center mb-6">
              <svg
                class="w-12 h-12 text-gray-400"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M13 10V3L4 14h7v7l9-11h-7z"
                >
                </path>
              </svg>
            </div>
            <h3 class="text-xl font-semibold text-gray-900 mb-2">No workouts yet</h3>
            <.button phx-click="createWorkout">
            Create
            </.button>

          </div>
        <% else %>
          <div class="mb-6">
            <form phx-change="search" class="flex items-center gap-3">
              <div class="relative flex-1 max-w-md">
                <svg class="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
                </svg>
                <input type="text" name="search" value={@search} placeholder="Search workouts..." phx-debounce="300" class="w-full pl-10 pr-4 py-2.5 rounded-lg border-gray-300 shadow-sm focus:ring-emerald-500 focus:border-emerald-500" />
              </div>
              <%= if @search != "" do %>
                <span class="text-sm text-gray-500">{@filtered_count} of {@total_count} workouts</span>
              <% end %>
            </form>
          </div>

          <div class="bg-white rounded-xl border border-gray-200 overflow-hidden">
            <table class="w-full text-sm">
              <thead>
                <tr class="border-b border-gray-200 bg-gray-50 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  <th class="px-4 py-3">Name</th>
                  <th class="px-4 py-3">Date</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <%= for workout <- @workouts do %>
                  <tr class="hover:bg-gray-50 transition-colors">
                    <td class="px-4 py-3">
                      <div class="flex items-center gap-3">
                        <.link navigate={~p"/client/workouts/#{workout.id}"} class="font-medium text-gray-900 hover:text-emerald-600">
                          <%= workout.name || "Untitled" %>
                        </.link>
                        <button
                          phx-click="deleteWorkout"
                          phx-value-id={workout.id}
                          data-confirm="Are you sure you want to delete this workout?"
                          class="text-xs text-red-400 hover:text-red-600 transition-colors"
                        >
                          Delete
                        </button>
                      </div>
                    </td>
                    <td class="px-4 py-3 text-gray-500">
                      <%= if workout.date do %>
                        <%= Calendar.strftime(workout.date, "%b %d, %Y") %>
                      <% else %>
                        —
                      <% end %>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>

          <%= if @total_pages > 1 do %>
            <div class="flex items-center justify-center gap-2 mt-8">
              <%= if @page > 1 do %>
                <button phx-click="page" phx-value-page={@page - 1} class="px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50">
                  Previous
                </button>
              <% end %>
              <%= for p <- max(1, @page - 2)..min(@total_pages, @page + 2)//1 do %>
                <button
                  phx-click="page"
                  phx-value-page={p}
                  class={"px-3 py-2 text-sm font-medium rounded-lg border #{if p == @page, do: "bg-emerald-600 text-white border-emerald-600", else: "text-gray-700 bg-white border-gray-300 hover:bg-gray-50"}"}
                >
                  {p}
                </button>
              <% end %>
              <%= if @page < @total_pages do %>
                <button phx-click="page" phx-value-page={@page + 1} class="px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50">
                  Next
                </button>
              <% end %>
            </div>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end
end
