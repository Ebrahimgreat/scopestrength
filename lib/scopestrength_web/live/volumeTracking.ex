defmodule ScopestrengthWeb.VolumeTracking do
  use ScopestrengthWeb, :live_view
  alias Scopestrength.Repo
  alias Scopestrength.Clients
  alias Scopestrength.Trainers
  alias Scopestrength.Training.WorkoutDetails
  alias Scopestrength.Training.Workout
  alias Scopestrength.Exercises.Exercise
  alias Scopestrength.Exercises.Muscles
  alias Scopestrength.Exercises.ExerciseMuscleContribution
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
            muscle_ids = Repo.all(from m in Muscles, select: {m.name, m.id}) |> Map.new()

            {:ok,
             assign(socket,
               client: client,
               client_id: client_id,
               period: period,
               volume_data: volume_data,
               muscle_ids: muscle_ids
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
    grouped_by = if period == "monthly", do: :month, else: :week

    # Query all workout details for this client
    workout_details =
      Repo.all(
        from wd in WorkoutDetails,
          join: w in Workout,
          on: wd.workout_id == w.id,
          join: e in Exercise,
          on: wd.exercise_id == e.id,
          where: w.client_id == ^client_id,
          select: %{
            workout_id: w.id,
            exercise_id: e.id,
            is_unilateral: e.is_unilateral,
            set: wd.set,
            side: wd.side,
            date: w.date
          }
      )

    # Get exercise IDs
    exercise_ids = workout_details |> Enum.map(& &1.exercise_id) |> Enum.uniq()

    # Get muscle contributions for these exercises
    muscle_contributions =
      if Enum.empty?(exercise_ids) do
        []
      else
        Repo.all(
          from c in ExerciseMuscleContribution,
            join: m in Muscles,
            on: c.muscle_id == m.id,
            where: c.exercise_id in ^exercise_ids,
            select: %{
              exercise_id: c.exercise_id,
              muscle_name: m.name,
              role: c.role,
              multiplier: c.multiplier
            }
        )
      end

    # Group contributions by exercise
    contributions_by_exercise = Enum.group_by(muscle_contributions, & &1.exercise_id)

    # Calculate sets with muscle contributions
    workout_details
    |> Enum.group_by(fn detail ->
      {detail.workout_id, detail.exercise_id, detail.set}
    end)
    |> Enum.flat_map(fn {{_workout_id, exercise_id, _set_num}, details} ->
      is_unilateral = List.first(details).is_unilateral

      # For unilateral: if both sides done = 1 set, if only one side = 0.5 set
      set_count = if is_unilateral do
        sides = details |> Enum.map(& &1.side) |> Enum.uniq()
        if length(sides) >= 2, do: 1.0, else: 0.5
      else
        1.0
      end

      # Get muscle contributions for this exercise
      contributions = Map.get(contributions_by_exercise, exercise_id, [])

      # Get date from first detail
      date = List.first(details).date

      # Return one entry per muscle that this exercise works
      Enum.map(contributions, fn c ->
        %{
          muscle_name: c.muscle_name,
          role: c.role,
          multiplier: c.multiplier,
          set_count: set_count,
          date: date
        }
      end)
    end)
    |> Enum.group_by(fn entry ->
      # Convert DateTime to Date for grouping
      workout_date = DateTime.to_date(entry.date)

      period_key =
        case grouped_by do
          :week ->
            {workout_date.year, Date.beginning_of_week(workout_date)}
          :month ->
            {workout_date.year, workout_date.month}
        end

      {entry.muscle_name, period_key}
    end)
    |> Enum.map(fn {{muscle_name, period_key}, entries} ->
      # Calculate total sets (all sets regardless of role)
      total_sets =
        entries
        |> Enum.map(& &1.set_count)
        |> Enum.sum()
        |> then(fn sum -> sum * 1.0 end)
        |> Float.round(1)

      # Calculate direct sets (primary role only)
      direct_sets =
        entries
        |> Enum.filter(fn e -> e.role == "primary" end)
        |> Enum.map(& &1.set_count * &1.multiplier)
        |> Enum.sum()
        |> then(fn sum -> sum * 1.0 end)
        |> Float.round(1)

      # Calculate effective sets (all roles with multipliers)
      effective_sets =
        entries
        |> Enum.map(& &1.set_count * &1.multiplier)
        |> Enum.sum()
        |> then(fn sum -> sum * 1.0 end)
        |> Float.round(1)

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
        total_sets: total_sets,
        direct_sets: direct_sets,
        effective_sets: effective_sets
      }
    end)
    |> Enum.sort_by(& &1.period_key, :desc)
    |> Enum.group_by(& &1.muscle_name)
    |> then(fn volume_by_muscle ->
      # Find earliest workout date to start periods from
      earliest_date =
        workout_details
        |> Enum.map(fn d -> DateTime.to_date(d.date) end)
        |> Enum.min(Date, fn -> Date.utc_today() end)

      all_periods = generate_all_periods(grouped_by, earliest_date)

      # Get all muscles so ones with 0 volume still show
      all_muscles = Repo.all(from m in Muscles, select: m.name, order_by: m.name)

      Enum.into(all_muscles, %{}, fn muscle_name ->
        existing = Map.get(volume_by_muscle, muscle_name, [])
        existing_by_key = Map.new(existing, fn p -> {p.period_key, p} end)

        filled_periods =
          Enum.map(all_periods, fn {period_key, period_label} ->
            Map.get(existing_by_key, period_key, %{
              muscle_name: muscle_name,
              period_label: period_label,
              period_key: period_key,
              total_sets: 0.0,
              direct_sets: 0.0,
              effective_sets: 0.0
            })
          end)

        {muscle_name, filled_periods}
      end)
    end)
  end

  defp generate_all_periods(:week, earliest_date) do
    today = Date.utc_today()
    start = Date.beginning_of_week(earliest_date)

    start
    |> Stream.iterate(&Date.add(&1, 7))
    |> Enum.take_while(&(Date.compare(&1, today) != :gt))
    |> Enum.map(fn week_start ->
      key = {week_start.year, week_start}
      label = "Week of #{Calendar.strftime(week_start, "%b %d")}"
      {key, label}
    end)
    |> Enum.sort_by(&elem(&1, 0), :desc)
  end

  defp generate_all_periods(:month, earliest_date) do
    today = Date.utc_today()

    Stream.iterate({earliest_date.year, earliest_date.month}, fn {y, m} ->
      if m == 12, do: {y + 1, 1}, else: {y, m + 1}
    end)
    |> Enum.take_while(fn {y, m} -> {y, m} <= {today.year, today.month} end)
    |> Enum.map(fn {y, m} ->
      key = {y, m}
      label = Calendar.strftime(Date.new!(y, m, 1), "%B %Y")
      {key, label}
    end)
    |> Enum.sort_by(&elem(&1, 0), :desc)
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
                <.link
                  navigate={"/trainer/clients/#{@client_id}/volumeTracking/#{@muscle_ids[muscle_name]}"}
                  class="text-base font-semibold text-gray-900 hover:text-emerald-600 transition-colors"
                >
                  <%= muscle_name %>
                </.link>
                <span class="text-xs font-medium text-gray-500">
                  <%= if @period == "weekly", do: "Weekly breakdown", else: "Monthly breakdown" %>
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
                        Direct Sets
                      </th>
                      <th class="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-gray-500 sm:px-6">
                        Effective Sets
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

                      <tr class={if period.total_sets == 0.0, do: "bg-amber-50/50 hover:bg-amber-50", else: "hover:bg-gray-50/70"}>
                        <td class="whitespace-nowrap px-4 py-3 text-sm font-medium text-gray-900 sm:px-6">
                          <div class="flex items-center gap-2">
                            <%= period.period_label %>
                            <%= if period.total_sets == 0.0 do %>
                              <span class="relative group cursor-help">
                                <svg class="w-4 h-4 text-amber-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                                </svg>
                                <span class="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 hidden group-hover:block w-48 px-3 py-2 text-xs text-white bg-gray-900 rounded-lg shadow-lg z-10">
                                  No sets recorded this <%= if @period == "weekly", do: "week", else: "month" %>
                                </span>
                              </span>
                            <% end %>
                          </div>
                        </td>
                        <td class="whitespace-nowrap px-4 py-3 text-right text-sm font-semibold text-gray-900 sm:px-6">
                          <%= period.total_sets %>
                        </td>
                        <td class="whitespace-nowrap px-4 py-3 text-right text-sm sm:px-6">
                          <span class="inline-flex items-center justify-center px-2 py-0.5 bg-emerald-600 text-white text-xs font-semibold rounded-full">
                            <%= period.direct_sets %>
                          </span>
                        </td>
                        <td class="whitespace-nowrap px-4 py-3 text-right text-sm sm:px-6">
                          <span class="inline-flex items-center justify-center px-2 py-0.5 bg-emerald-100 text-emerald-700 text-xs font-semibold rounded-full">
                            <%= period.effective_sets %>
                          </span>
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
