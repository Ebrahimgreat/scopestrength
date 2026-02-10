defmodule CrohnjobsWeb.VolumeTracking do
  use CrohnjobsWeb, :live_view
  alias Crohnjobs.Repo
  alias Crohnjobs.Clients
  alias Crohnjobs.Trainers
  alias Crohnjobs.Training.WorkoutDetails
  alias Crohnjobs.Training.Workout
  alias Crohnjobs.Exercises.Exercise
  alias Crohnjobs.Exercises.Muscles
  import Ecto.Query

  def mount(params, _session, socket) do
    client_id = String.to_integer(params["id"])
    user = socket.assigns.current_user
    trainer = Trainers.get_trainer_byUserId(user.id)

    case Repo.get(Clients.Client, client_id) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Client not found")
         |> push_navigate(to: "/trainer/clients")}

      client ->
        case client.trainer_id == trainer.id do
          true ->
            period = "weekly"
            volume_data = get_volume_data(client_id, period)

            {:ok,
             assign(socket,
               client: client,
               client_id: client_id,
               period: period,
               volume_data: volume_data
             )}

          false ->
            {:ok,
             socket
             |> put_flash(:error, "Client does not exist")
             |> push_navigate(to: "/trainer/clients")}
        end
    end
  end

  def handle_event("change_period", %{"period" => period}, socket) do
    volume_data = get_volume_data(socket.assigns.client_id, period)

    {:noreply,
     assign(socket,
       period: period,
       volume_data: volume_data
     )}
  end

  defp get_volume_data(client_id, period) do
    # Calculate date range based on period
    {start_datetime, grouped_by} =
      case period do
        "weekly" ->
          # Last 12 weeks
          start_date = Date.add(Date.utc_today(), -84)
          {DateTime.new!(start_date, ~T[00:00:00], "Etc/UTC"), :week}

        "monthly" ->
          # Last 6 months
          start_date = Date.add(Date.utc_today(), -180)
          {DateTime.new!(start_date, ~T[00:00:00], "Etc/UTC"), :month}

        _ ->
          start_date = Date.add(Date.utc_today(), -84)
          {DateTime.new!(start_date, ~T[00:00:00], "Etc/UTC"), :week}
      end

    # Query workout details with muscle group
    workout_details =
      Repo.all(
        from wd in WorkoutDetails,
          join: w in Workout,
          on: wd.workout_id == w.id,
          join: e in Exercise,
          on: wd.exercise_id == e.id,
          join: m in Muscles,
          on: e.muscle_id == m.id,
          where: w.client_id == ^client_id and w.date >= ^start_datetime,
          select: %{
            muscle_name: m.name,
            workout_id: w.id,
            exercise_id: e.id,
            is_unilateral: e.is_unilateral,
            set: wd.set,
            side: wd.side,
            date: w.date
          }
      )

    # Group by muscle and time period
    workout_details
    |> Enum.group_by(fn detail ->
      # Convert DateTime to Date for grouping
      workout_date = DateTime.to_date(detail.date)

      period_key =
        case grouped_by do
          :week ->
            # Get ISO week number
            {workout_date.year, Date.beginning_of_week(workout_date)}

          :month ->
            {workout_date.year, workout_date.month}
        end

      {detail.muscle_name, period_key}
    end)
    |> Enum.map(fn {{muscle_name, period_key}, details} ->
      # Count unique sets, handling unilateral exercises
      total_sets =
        details
        |> Enum.group_by(fn detail ->
          # For unilateral exercises, group by workout_id, exercise_id, and set number
          # This way left + right of the same set = 1 set
          if detail.is_unilateral do
            {detail.workout_id, detail.exercise_id, detail.set}
          else
            # For bilateral exercises, each record is a unique set
            {detail.workout_id, detail.exercise_id, detail.set, detail.side}
          end
        end)
        |> map_size()

      period_label =
        case grouped_by do
          :week ->
            {_year, week_start} = period_key
            "Week of #{Calendar.strftime(week_start, "%b %d")}"

          :month ->
            {year, month} = period_key
            date = Date.new!(year, month, 1)
            Calendar.strftime(date, "%B %Y")
        end

      %{
        muscle_name: muscle_name,
        period_label: period_label,
        period_key: period_key,
        total_sets: total_sets
      }
    end)
    |> Enum.sort_by(& &1.period_key, :desc)
    |> Enum.group_by(& &1.muscle_name)
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-6xl px-4 py-6 sm:px-6 lg:px-8">
      <div class="mb-6 rounded-xl border border-gray-200 bg-white p-5 sm:flex sm:items-center sm:justify-between">
        <div>
          <h1 class="text-2xl font-semibold text-gray-900">Volume Tracking</h1>
          <p class="mt-1 text-sm text-gray-600">
            Track training volume by muscle group over time
          </p>
        </div>

        <div class="mt-4 inline-flex rounded-lg bg-gray-100 p-1 sm:mt-0">
          <button
            phx-click="change_period"
            phx-value-period="weekly"
            class={[
              "rounded-md px-3 py-1.5 text-sm font-medium transition",
              if(@period == "weekly",
                do: "bg-white text-gray-900 shadow-sm ring-1 ring-inset ring-gray-200",
                else: "text-gray-600 hover:text-gray-900"
              )
            ]}
          >
            Weekly
          </button>
          <button
            phx-click="change_period"
            phx-value-period="monthly"
            class={[
              "rounded-md px-3 py-1.5 text-sm font-medium transition",
              if(@period == "monthly",
                do: "bg-white text-gray-900 shadow-sm ring-1 ring-inset ring-gray-200",
                else: "text-gray-600 hover:text-gray-900"
              )
            ]}
          >
            Monthly
          </button>
        </div>
      </div>

      <%= if map_size(@volume_data) == 0 do %>
        <div class="rounded-xl border border-dashed border-gray-300 bg-gray-50 p-8 text-center">
          <p class="text-gray-600">No workout data available yet.</p>
        </div>
      <% else %>
        <div class="space-y-4">
          <%= for {muscle_name, periods} <- @volume_data |> Enum.sort_by(fn {muscle, _} -> muscle end) do %>
            <section class="overflow-hidden rounded-xl border border-gray-200 bg-white">
              <div class="flex items-center justify-between border-b border-gray-200 bg-gray-50 px-4 py-3 sm:px-6">
                <h2 class="text-base font-semibold text-gray-900"><%= muscle_name %></h2>
                <span class="text-xs font-medium text-gray-500">
                  <%= if @period == "weekly", do: "Last 12 weeks", else: "Last 6 months" %>
                </span>
              </div>

              <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-gray-200">
                  <thead class="bg-white">
                    <tr>
                      <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-gray-500 sm:px-6">
                        Period
                      </th>
                      <th class="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-gray-500 sm:px-6">
                        Total Sets
                      </th>
                      <th class="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-gray-500 sm:px-6">
                        Change
                      </th>
                    </tr>
                  </thead>
                  <tbody class="bg-white divide-y divide-gray-200">
                    <%= for {period, index} <- Enum.with_index(periods) do %>
                      <% prev_period = Enum.at(periods, index + 1) %>
                      <% change =
                        if prev_period do
                          period.total_sets - prev_period.total_sets
                        else
                          nil
                        end %>
                      <% change_percent =
                        if prev_period && prev_period.total_sets > 0 do
                          (change / prev_period.total_sets * 100) |> Float.round(1)
                        else
                          nil
                        end %>

                      <tr class="hover:bg-gray-50/70">
                        <td class="whitespace-nowrap px-4 py-3 text-sm font-medium text-gray-900 sm:px-6">
                          <%= period.period_label %>
                        </td>
                        <td class="whitespace-nowrap px-4 py-3 text-right text-sm font-semibold text-gray-900 sm:px-6">
                          <%= period.total_sets %>
                        </td>
                        <td class="whitespace-nowrap px-4 py-3 text-right text-sm sm:px-6">
                          <%= if change do %>
                            <span class={[
                              "inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium ring-1 ring-inset",
                              cond do
                                change > 0 -> "bg-emerald-50 text-emerald-700 ring-emerald-200"
                                change < 0 -> "bg-rose-50 text-rose-700 ring-rose-200"
                                true -> "bg-gray-100 text-gray-700 ring-gray-200"
                              end
                            ]}>
                              <%= if change > 0, do: "+", else: "" %><%= change %> sets
                              <%= if change_percent, do: "(#{change_percent}%)" %>
                            </span>
                          <% else %>
                            <span class="text-gray-400">—</span>
                          <% end %>
                        </td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>
            </section>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end
end
