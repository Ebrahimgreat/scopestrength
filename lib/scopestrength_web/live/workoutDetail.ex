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

defmodule ScopestrengthWeb.WorkoutDetail do
  alias Scopestrength.Trainers
  alias Scopestrength.Clients.Client
  alias Scopestrength.Exercises.ExerciseMuscleContribution
  alias Scopestrength.Repo
  alias Scopestrength.Training.Workout
  alias Scopestrength.Training.WorkoutDetails
  use ScopestrengthWeb, :live_view
  import Ecto.Query

  def mount(params, _session, socket) do
    user = socket.assigns.current_user
    trainer = Trainers.get_trainer_byUserId(user.id)

    with {:ok, client_id} <- parse_id(params["id"]),
         {:ok, workout_id} <- parse_id(params["workout_id"]),
         %Client{} = client <- Repo.get(Client, client_id) |> Repo.preload(:user),
         true <- client.trainer_id == trainer.id,
         %Workout{} = workout <- Repo.get_by(Workout, id: workout_id, client_id: client.id) do
      workouts =
        Repo.all(
          from w in WorkoutDetails,
            where: w.workout_id == ^workout_id,
            order_by: [asc: w.set]
        )
        |> Repo.preload([:exercise])

      {grouped_workouts, muscle_group_frequencies} = build_workout_assigns(workouts)

      {:ok,
       socket
       |> assign(:client, client)
       |> assign(:workout, workout)
       |> assign(:workouts, grouped_workouts)
       |> assign(:muscle_group_frequencies, muscle_group_frequencies)}
    else
      _ ->
        {:ok,
         socket
         |> put_flash(:error, "Workout not found")
         |> redirect(to: "/trainer/clients")}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-5xl">
      <div class="flex flex-wrap items-end justify-between gap-4">
        <div class="min-w-0">
          <.link
            navigate={~p"/trainer/clients/#{@client.id}/workouts"}
            class="inline-flex items-center gap-1 text-xs font-medium uppercase tracking-widest text-dim transition hover:text-foreground"
          >
            <.icon name="hero-chevron-left" class="h-3 w-3" /> Workouts
          </.link>
          <h1 class="mt-1 font-display text-5xl font-bold uppercase tracking-wide text-foreground">
            <%= @workout.name || "Training Session" %>
          </h1>
          <p class="num mt-2 text-sm text-dim">
            <%= if @workout.date do %>
              <%= Calendar.strftime(@workout.date, "%b %d, %Y") %> ·
            <% end %>
            <%= @client.user && @client.user.name %>
          </p>
        </div>

        <div :if={@workouts != %{}} class="flex shrink-0 gap-6">
          <div>
            <p class="text-xs uppercase tracking-widest text-faint">Exercises</p>
            <p class="num mt-1 text-2xl font-bold text-foreground"><%= map_size(@workouts) %></p>
          </div>
          <div>
            <p class="text-xs uppercase tracking-widest text-faint">Sets</p>
            <p class="num mt-1 text-2xl font-bold text-foreground"><%= total_sets(@workouts) %></p>
          </div>
          <div>
            <p class="text-xs uppercase tracking-widest text-faint">Volume</p>
            <p class="num mt-1 text-2xl font-bold text-foreground"><%= total_volume(@workouts) %></p>
          </div>
        </div>
      </div>

      <div
        :if={@workouts == %{}}
        class="mt-8 rounded-xl border border-dashed border-line px-6 py-16 text-center"
      >
        <h3 class="font-display text-xl font-bold uppercase tracking-wide text-foreground">
          No exercises logged
        </h3>
        <p class="mx-auto mt-2 max-w-sm text-sm text-dim">
          This workout has no logged exercises yet.
        </p>
      </div>

      <div :if={map_size(@muscle_group_frequencies) > 0} class="mt-8 rounded-xl border border-line bg-card p-5">
        <div class="flex items-baseline justify-between gap-3">
          <h2 class="text-sm font-semibold text-foreground">Session Volume</h2>
          <span class="text-xs text-dim">Direct vs effective sets</span>
        </div>

        <% volume_max =
          @muscle_group_frequencies
          |> Enum.map(fn {_m, v} -> v.effective end)
          |> Enum.max(fn -> 0.0 end) %>

        <div class="mt-4 space-y-2.5">
          <div :for={{muscle_group, volumes} <- @muscle_group_frequencies}>
            <div class="flex items-baseline justify-between gap-3">
              <span class="truncate text-sm text-foreground"><%= muscle_group %></span>
              <span class="num shrink-0 text-xs text-dim">
                <%= round(volumes.direct) %> direct · <%= round(volumes.effective) %> effective
              </span>
            </div>
            <div class="mt-1.5 h-1.5 w-full overflow-hidden rounded-full bg-muted">
              <div
                class="h-full rounded-full bg-primary"
                style={"width: #{bar_pct(volumes.effective, volume_max)}%"}
              >
              </div>
            </div>
          </div>
        </div>
      </div>

      <div :if={@workouts != %{}} class="mt-8 space-y-4">
        <div
          :for={{_exercise_id, sets} <- @workouts}
          class="overflow-hidden rounded-xl border border-line bg-card"
        >
          <div class="flex items-baseline justify-between gap-3 border-b border-line px-5 py-4">
            <h3 class="font-semibold text-foreground">
              <%= List.first(sets).data.exercise.name %>
            </h3>
            <span class="num text-xs text-dim"><%= length(sets) %> sets</span>
          </div>

          <div class="grid grid-cols-[2rem,1fr,1fr,1fr,1fr] gap-3 px-5 pt-3">
            <span class="text-[11px] uppercase tracking-widest text-faint">Set</span>
            <span class="text-[11px] uppercase tracking-widest text-faint">Weight</span>
            <span class="text-[11px] uppercase tracking-widest text-faint">Reps</span>
            <span class="text-[11px] uppercase tracking-widest text-faint">RIR</span>
            <span class="text-[11px] uppercase tracking-widest text-faint">RPE</span>
          </div>

          <div class="px-5 pb-3">
            <div
              :for={workout <- sets}
              class="grid grid-cols-[2rem,1fr,1fr,1fr,1fr] items-baseline gap-3 border-b border-line/60 py-2.5 last:border-0"
            >
              <span class="num text-sm text-dim"><%= workout.data.set %></span>
              <span class="num text-base text-foreground">
                <%= workout.data.weight %><span class="ml-1 text-xs text-faint">kg</span>
              </span>
              <span class="num text-base text-foreground"><%= workout.data.reps %></span>
              <span class="num text-base text-foreground"><%= workout.data.rir || 0 %></span>
              <span class="num text-base text-foreground">
                <%= if workout.data.rpe, do: workout.data.rpe, else: "—" %>
              </span>

              <span
                :if={workout.data.side != "both"}
                class="col-start-2 -mt-1 inline-flex w-fit items-center rounded-full bg-secondary px-2 py-0.5 text-[10px] uppercase tracking-widest text-dim"
              >
                <%= workout.data.side %>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp total_sets(workouts) do
    workouts |> Enum.map(fn {_id, sets} -> length(sets) end) |> Enum.sum()
  end

  defp total_volume(workouts) do
    workouts
    |> Enum.flat_map(fn {_id, sets} -> sets end)
    |> Enum.map(fn form -> (form.data.reps || 0.0) * (form.data.weight || 0.0) end)
    |> Enum.sum()
    |> then(fn total ->
      if total >= 1000, do: "#{Float.round(total / 1000, 1)}k", else: round(total)
    end)
  end

  defp bar_pct(_value, max) when max <= 0, do: 0
  defp bar_pct(value, max), do: Float.round(value / max * 100, 2)

  defp parse_id(nil), do: :error

  defp parse_id(value) do
    case Integer.parse(value) do
      {id, ""} -> {:ok, id}
      _ -> :error
    end
  end

  defp build_workout_assigns(workouts) do
    changesets =
      Enum.map(workouts, fn workout ->
        workout |> Scopestrength.Training.change_workout_details() |> to_form()
      end)

    grouped_workouts = Enum.group_by(changesets, fn form -> form.data.exercise_id end)
    muscle_group_frequencies = build_volume_from_workouts(workouts)

    {grouped_workouts, muscle_group_frequencies}
  end

  defp build_volume_from_workouts(workouts) do
    exercise_ids =
      workouts
      |> Enum.map(& &1.exercise_id)
      |> Enum.uniq()

    if Enum.empty?(exercise_ids) do
      %{}
    else
      workouts = Repo.preload(workouts, :exercise)

      muscle_contributions =
        Repo.all(
          from c in ExerciseMuscleContribution,
            where: c.exercise_id in ^exercise_ids
        )
        |> Repo.preload(:muscle)

      contributions_by_exercise =
        muscle_contributions
        |> Enum.group_by(& &1.exercise_id)

      workouts_with_volume =
        workouts
        |> Enum.group_by(fn detail ->
          {detail.exercise_id, detail.exercise.is_unilateral, detail.set}
        end)
        |> Enum.flat_map(fn {{exercise_id, is_unilateral, _set_num}, details} ->
          if is_unilateral do
            sides = details |> Enum.map(& &1.side) |> Enum.uniq()
            set_count = if length(sides) >= 2, do: 1.0, else: 0.5

            contributions = Map.get(contributions_by_exercise, exercise_id, [])
            Enum.map(contributions, fn c ->
              {c.muscle.name, c.role, set_count * c.multiplier}
            end)
          else
            Enum.flat_map(details, fn _detail ->
              contributions = Map.get(contributions_by_exercise, exercise_id, [])
              Enum.map(contributions, fn c ->
                {c.muscle.name, c.role, 1 * c.multiplier}
              end)
            end)
          end
        end)

      workouts_with_volume
      |> Enum.group_by(fn {muscle, _role, _volume} -> muscle end)
      |> Enum.map(fn {muscle, rows} ->
        direct_sets =
          rows
          |> Enum.filter(fn {_m, role, _v} -> role == "primary" end)
          |> Enum.map(fn {_m, _r, v} -> v end)
          |> Enum.sum()

        effective_sets =
          rows
          |> Enum.map(fn {_m, _r, v} -> v end)
          |> Enum.sum()

        {muscle, %{direct: direct_sets, effective: effective_sets}}
      end)
      |> Map.new()
    end
  end

end
