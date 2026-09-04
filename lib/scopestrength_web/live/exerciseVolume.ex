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

defmodule ScopestrengthWeb.ExerciseVolume do
  alias Scopestrength.Repo
  alias Scopestrength.Trainers
  use ScopestrengthWeb, :live_view
  import Ecto.Query

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    trainer = Trainers.get_trainer_byUserId(user.id)

    exercise_muscle_contributions =
      Repo.all(
        from em in Scopestrength.Exercises.ExerciseMuscleContribution,
          where: is_nil(em.trainer_id) or em.trainer_id == ^trainer.id
      )
      |> Repo.preload(:exercise)
      |> Repo.preload(:muscle)

    {:ok,
     assign(socket,
       allExerciseMuscleContributions: exercise_muscle_contributions,
       exerciseMuscleContributions: exercise_muscle_contributions,
       search: "",
       custom_only: false,
       show_edit_dialog: false,
       editing_contribution: nil
     )}
  end

  defp apply_filters(contributions, search, custom_only) do
    contributions
    |> Enum.filter(fn emc -> !custom_only or emc.exercise.is_custom end)
    |> Enum.filter(&matches_search?(&1, search))
  end

  defp matches_search?(_emc, ""), do: true

  defp matches_search?(emc, search) do
    needle = String.downcase(search)

    [emc.exercise.name, emc.muscle.name]
    |> Enum.any?(fn value -> value && String.contains?(String.downcase(value), needle) end)
  end

  defp group_by_exercise(contributions) do
    contributions
    |> Enum.group_by(& &1.exercise)
    |> Enum.sort_by(fn {exercise, _rows} -> String.downcase(exercise.name || "") end)
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-6xl">
      <.back_link navigate={~p"/trainer/exercises"}>Exercises</.back_link>
      <div class="flex flex-wrap items-end justify-between gap-4">
        <div>
          <p class="text-xs font-medium uppercase tracking-widest text-dim">Training analytics</p>
          <h1 class="mt-1 font-display text-5xl font-bold uppercase tracking-wide text-foreground">
            Exercise Volume
          </h1>
          <p class="mt-1 max-w-2xl text-sm text-dim">
            Review muscle contribution multipliers for each exercise.
          </p>
        </div>
      </div>

      <div class="mt-6 rounded-2xl border border-line bg-muted px-4 py-3">
        <p class="mb-2 text-xs font-semibold uppercase tracking-[0.2em] text-primary">
          Volume Calculation Guide
        </p>
        <div class="space-y-1 text-xs text-dim">
          <p><span class="font-semibold">1.0 multiplier:</span> 1 set = 1 set of volume</p>
          <p><span class="font-semibold">0.5 multiplier:</span> 1 sets = 0.5 set of volume</p>
          <p class="pt-1 italic">Example: If you do 3 sets with 0.5 multiplier, the muscle gets 1.5 sets of effective volume.</p>
        </div>
      </div>

      <form phx-change="searching" phx-debounce="250" class="mt-8">
        <input
          type="search"
          name="search"
          value={@search}
          placeholder="Search exercises or muscle groups"
          aria-label="Search exercises"
          class="w-full rounded-xl border-line bg-card px-5 py-4 text-base text-foreground placeholder:text-faint focus:border-primary focus:ring-0"
        />
      </form>

      <div class="mt-3 flex items-center gap-2">
        <button
          type="button"
          phx-click="toggle_custom_only"
          aria-pressed={to_string(@custom_only)}
          class={[
            "rounded-full px-3 py-1.5 text-xs font-medium transition",
            @custom_only && "bg-primary/15 text-primary",
            !@custom_only && "bg-muted text-dim hover:text-foreground"
          ]}
        >
          Custom exercises only
        </button>
      </div>

      <div :if={@exerciseMuscleContributions == []} class="mt-6 rounded-xl border border-dashed border-line px-6 py-16 text-center">
        <h3 class="font-display text-xl font-bold uppercase tracking-wide text-foreground">
          {if @allExerciseMuscleContributions == [], do: "No exercises yet", else: "No matches"}
        </h3>
        <p class="mx-auto mt-2 max-w-sm text-sm text-dim">
          {if @allExerciseMuscleContributions == [],
            do: "Muscle contributions will show up once exercises have them.",
            else: "Try a different name or muscle group."}
        </p>
        <div :if={@allExerciseMuscleContributions != []} class="mt-6">
          <button
            type="button"
            phx-click="resetFilters"
            class="text-sm font-medium text-primary transition hover:opacity-80"
          >
            Clear filters
          </button>
        </div>
      </div>

      <div :if={@exerciseMuscleContributions != []} class="mt-6 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
        <div
          :for={{exercise, rows} <- group_by_exercise(@exerciseMuscleContributions)}
          class="flex flex-col rounded-xl border border-line bg-card p-5"
        >
          <div class="flex items-start justify-between gap-2">
            <h3 class="font-semibold leading-snug text-foreground">{exercise.name}</h3>
            <span :if={exercise.is_custom} class="num shrink-0 inline-flex items-center rounded-full border border-primary/40 px-2.5 py-1 text-xs text-primary">
              Custom
            </span>
          </div>

          <ul class="mt-3 space-y-2">
            <li :for={emc <- Enum.sort_by(rows, & &1.role)} class="flex items-center justify-between gap-3 rounded-lg bg-muted px-3 py-2">
              <div class="min-w-0">
                <p class="truncate text-sm font-medium text-foreground">{emc.muscle.name}</p>
                <p class="text-xs capitalize text-dim">{emc.role}</p>
              </div>
              <span class="num shrink-0 text-sm font-semibold text-foreground">{emc.multiplier}</span>
            </li>
          </ul>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("searching", params, socket) do
    search = params["search"] || ""

    {:noreply,
     assign(socket,
       search: search,
       exerciseMuscleContributions:
         apply_filters(socket.assigns.allExerciseMuscleContributions, search, socket.assigns.custom_only)
     )}
  end

  def handle_event("toggle_custom_only", _params, socket) do
    custom_only = !socket.assigns.custom_only

    {:noreply,
     assign(socket,
       custom_only: custom_only,
       exerciseMuscleContributions:
         apply_filters(socket.assigns.allExerciseMuscleContributions, socket.assigns.search, custom_only)
     )}
  end

  def handle_event("resetFilters", _params, socket) do
    {:noreply,
     assign(socket,
       search: "",
       custom_only: false,
       exerciseMuscleContributions: socket.assigns.allExerciseMuscleContributions
     )}
  end

  def handle_event("edit_multiplier", %{"id" => id}, socket) do
    contribution =
      Enum.find(socket.assigns.exerciseMuscleContributions, &(&1.id == String.to_integer(id)))

    if contribution do
      changeset = Scopestrength.Exercises.ExerciseMuscleContribution.changeset(contribution, %{})

      {:noreply,
       assign(socket,
         show_edit_dialog: true,
         editing_contribution: contribution,
         edit_form: to_form(changeset)
       )}
    else
      {:noreply, socket}
    end
  end

  def handle_event("save_multiplier", params, socket) do
    contribution_id = String.to_integer(params["exercise_muscle_contribution"]["id"])
    multiplier = String.to_float(params["exercise_muscle_contribution"]["multiplier"])

    contribution =
      Enum.find(socket.assigns.exerciseMuscleContributions, &(&1.id == contribution_id))

    if contribution do
      attrs = %{multiplier: multiplier}

      case Scopestrength.Exercises.update_exercise_muscle_contribution(contribution, attrs) do
        {:ok, updated_contribution} ->
          updated_list =
            Enum.map(socket.assigns.exerciseMuscleContributions, fn c ->
              if c.id == contribution_id, do: updated_contribution, else: c
            end)

          {:noreply,
           socket
           |> assign(
             exerciseMuscleContributions: updated_list,
             show_edit_dialog: false,
             editing_contribution: nil
           )
           |> put_flash(:info, "Multiplier updated successfully")}

        {:error, changeset} ->
          {:noreply, assign(socket, edit_form: to_form(changeset))}
      end
    else
      {:noreply, socket |> put_flash(:error, "Contribution not found")}
    end
  end

  def handle_event("close_edit_dialog", _params, socket) do
    {:noreply, assign(socket, show_edit_dialog: false, editing_contribution: nil, edit_form: nil)}
  end
end
