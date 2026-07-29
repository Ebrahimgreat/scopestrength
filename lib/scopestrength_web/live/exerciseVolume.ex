defmodule ScopestrengthWeb.ExerciseVolume do
  alias Scopestrength.Repo
  alias Scopestrength.Trainers
  alias Scopestrength.Accounts.Trainer
  use ScopestrengthWeb, :live_view
  import Ecto.Query

  def mount(params, session, socket) do
    user = socket.assigns.current_user
    trainer = Trainers.get_trainer_byUserId(user.id)

    exercise_muscle_contributions =
      Repo.all(
        from em in Scopestrength.Exercises.ExerciseMuscleContribution,
          where: is_nil(em.trainer_id) or em.trainer_id == ^trainer.id
      )
      |> Repo.preload(:exercise)
      |> Repo.preload(:muscle)

    IO.inspect(exercise_muscle_contributions)

    {:ok,
     assign(socket,
       exerciseMuscleContributions: exercise_muscle_contributions,
       show_edit_dialog: false,
       editing_contribution: nil
     )}
  end

  def render(assigns) do
    ~H"""

      <div class="relative px-6 py-7 sm:px-8">
        <div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <p class="text-xs font-semibold uppercase tracking-[0.35em] text-faint">
              Training analytics
            </p>
            <h1 class="text-2xl font-semibold text-foreground sm:text-3xl">Exercise Volume</h1>
            <p class="mt-1 max-w-2xl text-sm text-dim">
              Review muscle contribution multipliers for each exercise.
            </p>
          </div>
        </div>

        <div class="mt-3 rounded-2xl border border-blue-200 bg-blue-50/80 px-4 py-3">
          <p class="text-xs font-semibold uppercase tracking-[0.2em] text-blue-700 mb-2">
            Volume Calculation Guide
          </p>
          <div class="text-xs text-blue-800 space-y-1">
            <p><span class="font-semibold">1.0 multiplier:</span> 1 set = 1 set of volume</p>
            <p><span class="font-semibold">0.5 multiplier:</span> 1 sets = 0.5 set of volume</p>
            <p class="pt-1 italic">Example: If you do 3 sets with 0.5 multiplier, the muscle gets 1.5 sets of effective volume.</p>
          </div>
        </div>
      </div>

      <div class="relative overflow-hidden border-t border-line">
        <table class="w-full text-sm">
          <thead class="bg-card/80 text-[0.7rem] uppercase tracking-[0.2em] text-faint">
            <tr>
              <th class="text-left py-3 px-6 font-semibold">Exercise</th>
              <th class="text-left py-3 px-6 font-semibold">Muscle</th>
              <th class="text-left py-3 px-6 font-semibold">Role</th>
              <th class="text-left py-3 px-6 font-semibold">Multiplier</th>
              <th class="text-right py-3 px-6 font-semibold">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-line">
            <%= for emc <- @exerciseMuscleContributions do %>
              <tr class="transition hover:bg-card">
                <td class="px-6 py-3 font-medium text-foreground"><%= emc.exercise.name %></td>
                <td class="px-6 py-3 text-dim"><%= emc.muscle.name %></td>
                <td class="px-6 py-3">
                  <span class="inline-flex items-center rounded-full px-2.5 py-1 text-xs font-semibold capitalize">
                    <%= emc.role %>
                  </span>
                </td>
                <td class="px-6 py-3 text-foreground"><%= emc.multiplier %></td>
                <td class="px-6 py-3 text-right">
                  <span class="text-xs text-faint">
                    <%= if emc.role == "primary", do: "Primary", else: "View only" %>
                  </span>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    """
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
