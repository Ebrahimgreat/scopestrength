# ScopeStrength - personal trainer management application
# Copyright (C) 2026  Ebrahim Shahid Arshad
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# SPDX-License-Identifier: AGPL-3.0-or-later

defmodule ScopestrengthWeb.Client.VolumeTracking do
  use ScopestrengthWeb, :live_view
  alias Scopestrength.Repo
  alias Scopestrength.Clients
  alias Scopestrength.Training.WorkoutDetails
  alias Scopestrength.Training.Workout
  alias Scopestrength.Exercises.Exercise
  alias Scopestrength.Exercises.Muscles
  alias Scopestrength.Exercises.ExerciseMuscleContribution
  import Ecto.Query

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    client = Clients.get_client_byUserId(user.id)

    period = "weekly"
    volume_data = get_volume_data(client.id, period)
    muscle_ids = Repo.all(from m in Muscles, select: {m.name, m.id}) |> Map.new()

    {:ok,
     assign(socket,
       client: client,
       client_id: client.id,
       period: period,
       volume_data: volume_data,
       muscle_ids: muscle_ids,
       period_index: 0,
       expanded: nil
     )}
  end

  def handle_event("change_period", %{"period" => period}, socket) do
    volume_data = get_volume_data(socket.assigns.client_id, period)

    {:noreply,
     assign(socket,
       period: period,
       volume_data: volume_data,
       period_index: 0,
       expanded: nil
     )}
  end

  def handle_event("step_period", %{"by" => by}, socket) do
    max_index = max(period_count(socket.assigns.volume_data) - 1, 0)

    index =
      (socket.assigns.period_index + String.to_integer(by))
      |> max(0)
      |> min(max_index)

    {:noreply, assign(socket, period_index: index)}
  end

  def handle_event("toggle_muscle", %{"muscle" => muscle}, socket) do
    expanded = if socket.assigns.expanded == muscle, do: nil, else: muscle
    {:noreply, assign(socket, expanded: expanded)}
  end

  defp get_volume_data(client_id, period) do
    grouped_by = if period == "monthly", do: :month, else: :week

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

    exercise_ids = workout_details |> Enum.map(& &1.exercise_id) |> Enum.uniq()

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
              muscle_id: m.id,
              role: c.role,
              multiplier: c.multiplier
            }
        )
      end

    contributions_by_exercise = Enum.group_by(muscle_contributions, & &1.exercise_id)

    workout_details
    |> Enum.group_by(fn detail ->
      {detail.workout_id, detail.exercise_id, detail.set}
    end)
    |> Enum.flat_map(fn {{_workout_id, exercise_id, _set_num}, details} ->
      is_unilateral = List.first(details).is_unilateral

      set_count = if is_unilateral do
        sides = details |> Enum.map(& &1.side) |> Enum.uniq()
        if length(sides) >= 2, do: 1.0, else: 0.5
      else
        1.0
      end

      contributions = Map.get(contributions_by_exercise, exercise_id, [])

      date = List.first(details).date

      Enum.map(contributions, fn c ->
        %{
          muscle_name: c.muscle_name,
          muscle_id: c.muscle_id,
          role: c.role,
          multiplier: c.multiplier,
          set_count: set_count,
          date: date
        }
      end)
    end)
    |> Enum.group_by(fn entry ->
      workout_date = DateTime.to_date(entry.date)

      period_key =
        case grouped_by do
          :week ->
            week_start = Date.beginning_of_week(workout_date)
            {week_start.year, week_start.month, week_start.day}
          :month ->
            {workout_date.year, workout_date.month}
        end

      {entry.muscle_name, period_key}
    end)
    |> Enum.map(fn {{muscle_name, period_key}, entries} ->
      total_sets =
        entries
        |> Enum.map(& &1.set_count)
        |> Enum.sum()
        |> then(fn sum -> sum * 1.0 end)
        |> Float.round(1)

      direct_sets =
        entries
        |> Enum.filter(fn e -> e.role == "primary" end)
        |> Enum.map(& &1.set_count * &1.multiplier)
        |> Enum.sum()
        |> then(fn sum -> sum * 1.0 end)
        |> Float.round(1)

      effective_sets =
        entries
        |> Enum.map(& &1.set_count * &1.multiplier)
        |> Enum.sum()
        |> then(fn sum -> sum * 1.0 end)
        |> Float.round(1)

      period_label =
        case grouped_by do
          :week ->
            {y, m, d} = period_key
            "Week of #{Calendar.strftime(Date.new!(y, m, d), "%b %d")}"
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
      earliest_date =
        workout_details
        |> Enum.map(fn d -> DateTime.to_date(d.date) end)
        |> Enum.min(Date, fn -> Date.utc_today() end)

      all_periods = generate_all_periods(grouped_by, earliest_date)

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
      key = {week_start.year, week_start.month, week_start.day}
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
    assigns = assign(assigns, rows: current_rows(assigns.volume_data, assigns.period_index))

    ~H"""
    <div class="mx-auto max-w-5xl">
      <.back_link navigate={~p"/client"}>Dashboard</.back_link>
      <div class="flex flex-wrap items-end justify-between gap-4">
        <div>
          <p class="text-xs font-medium uppercase tracking-widest text-dim">Training</p>
          <h1 class="mt-1 font-display text-5xl font-bold uppercase tracking-wide text-foreground">
            Volume
          </h1>
        </div>

        <div class="inline-flex rounded-lg bg-muted p-1">
          <button
            :for={{value, label} <- [{"weekly", "Weekly"}, {"monthly", "Monthly"}]}
            phx-click="change_period"
            phx-value-period={value}
            class={[
              "rounded-md px-3 py-1.5 text-sm font-medium transition",
              @period == value && "bg-card text-foreground",
              @period != value && "text-dim hover:text-foreground"
            ]}
          >
            {label}
          </button>
        </div>
      </div>

      <%= if map_size(@volume_data) == 0 do %>
        <div class="mt-8 rounded-xl border border-dashed border-line px-6 py-16 text-center">
          <h3 class="font-display text-xl font-bold uppercase tracking-wide text-foreground">
            No volume yet
          </h3>
          <p class="mx-auto mt-2 max-w-sm text-sm text-dim">
            Log a workout and your set volume will break down by muscle here.
          </p>
        </div>
      <% else %>
        <div class="mt-8 overflow-hidden rounded-xl border border-line bg-card">
          <div class="flex items-center justify-between border-b border-line px-5 py-4">
            <div class="min-w-0">
              <p class="truncate text-sm font-semibold text-foreground">{@rows.label}</p>
              <p class="num mt-0.5 text-xs text-dim">
                {format_sets(@rows.total_direct)} direct · {format_sets(@rows.total_effective)} effective
              </p>
            </div>

            <div class="flex shrink-0 items-center gap-1">
              <button
                phx-click="step_period"
                phx-value-by="1"
                disabled={!@rows.has_older}
                aria-label="Earlier period"
                class="rounded-md p-1.5 text-dim transition enabled:hover:bg-secondary enabled:hover:text-foreground disabled:opacity-30"
              >
                <.icon name="hero-chevron-left" class="h-4 w-4" />
              </button>
              <button
                phx-click="step_period"
                phx-value-by="-1"
                disabled={@period_index == 0}
                aria-label="Later period"
                class="rounded-md p-1.5 text-dim transition enabled:hover:bg-secondary enabled:hover:text-foreground disabled:opacity-30"
              >
                <.icon name="hero-chevron-right" class="h-4 w-4" />
              </button>
            </div>
          </div>

          <div :if={@rows.max == 0} class="px-5 py-12 text-center text-sm text-dim">
            No sets recorded in this {if @period == "weekly", do: "week", else: "month"}.
          </div>

          <div :if={@rows.max > 0} class="divide-y divide-line/60">
            <div :for={row <- @rows.muscles} class="px-5 py-3">
              <button
                type="button"
                phx-click="toggle_muscle"
                phx-value-muscle={row.muscle_name}
                aria-expanded={to_string(@expanded == row.muscle_name)}
                class="group block w-full text-left"
              >
                <div class="flex items-baseline justify-between gap-3">
                  <span class="truncate text-sm font-medium text-foreground">
                    {row.muscle_name}
                  </span>
                  <span class="num shrink-0 text-xs text-dim">
                    <span class="text-foreground">{format_sets(row.direct_sets)}</span>
                    <span :if={row.indirect > 0}> + {format_sets(row.indirect)}</span>
                  </span>
                </div>

                <div class="mt-2 h-2 w-full overflow-hidden rounded-full bg-muted">
                  <div class="flex h-full">
                    <div
                      class="h-full rounded-l-full bg-primary transition-all"
                      style={"width: #{pct(row.direct_sets, @rows.max)}%"}
                    >
                    </div>
                    <div
                      class="h-full bg-primary/30 transition-all"
                      style={"width: #{pct(row.indirect, @rows.max)}%"}
                    >
                    </div>
                  </div>
                </div>
              </button>

              <div :if={@expanded == row.muscle_name} class="mt-3 space-y-2 border-l border-line pl-4">
                <p class="text-xs uppercase tracking-widest text-dim">Recent {@period} history</p>
                <div
                  :for={p <- Enum.take(Map.get(@volume_data, row.muscle_name, []), 8)}
                  class="flex items-baseline justify-between gap-3 text-xs"
                >
                  <span class="truncate text-dim">{p.period_label}</span>
                  <span class="num shrink-0 text-dim">
                    <span class="text-foreground">{format_sets(p.direct_sets)}</span>
                    / {format_sets(p.effective_sets)}
                  </span>
                </div>
                <.link
                  navigate={"/client/volumeTracking/#{@muscle_ids[row.muscle_name]}"}
                  class="inline-block pt-1 text-xs font-medium text-primary hover:opacity-80"
                >
                  Exercise breakdown →
                </.link>
              </div>
            </div>
          </div>

          <div class="flex items-center gap-4 border-t border-line px-5 py-3 text-xs text-dim">
            <span class="inline-flex items-center gap-1.5">
              <span class="h-2 w-4 rounded-full bg-primary"></span> Direct
            </span>
            <span class="inline-flex items-center gap-1.5">
              <span class="h-2 w-4 rounded-full bg-primary/30"></span> Indirect
            </span>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp pct(_value, 0), do: 0
  defp pct(_value, max) when max <= 0, do: 0
  defp pct(value, max), do: Float.round(value / max * 100, 2)

  defp format_sets(value) do
    rounded = Float.round(value * 1.0, 1)
    if rounded == Float.round(rounded, 0), do: trunc(rounded), else: rounded
  end

  defp period_count(volume_data) do
    volume_data
    |> Map.values()
    |> Enum.map(&length/1)
    |> Enum.min(fn -> 0 end)
  end

  defp current_rows(volume_data, index) do
    muscles =
      volume_data
      |> Enum.map(fn {muscle_name, periods} ->
        p = Enum.at(periods, index)

        %{
          muscle_name: muscle_name,
          period_label: p && p.period_label,
          direct_sets: (p && p.direct_sets) || 0.0,
          effective_sets: (p && p.effective_sets) || 0.0,
          indirect: max(((p && p.effective_sets) || 0.0) - ((p && p.direct_sets) || 0.0), 0.0)
        }
      end)
      |> Enum.sort_by(& &1.effective_sets, :desc)

    %{
      muscles: muscles,
      label: muscles |> Enum.find_value(& &1.period_label) || "—",
      max: muscles |> Enum.map(& &1.effective_sets) |> Enum.max(fn -> 0.0 end),
      total_direct: muscles |> Enum.map(& &1.direct_sets) |> Enum.sum(),
      total_effective: muscles |> Enum.map(& &1.effective_sets) |> Enum.sum(),
      has_older: index + 1 < period_count(volume_data)
    }
  end

end
