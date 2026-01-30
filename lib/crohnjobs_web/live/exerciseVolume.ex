defmodule CrohnjobsWeb.ExerciseVolume do
  alias Crohnjobs.Repo
  alias Crohnjobs.Trainers
  alias Crohnjobs.Accounts.Trainer
  use CrohnjobsWeb, :live_view
  import Ecto.Query

  def mount(params, session, socket) do
    user = socket.assigns.current_user
    trainer = Trainers.get_trainer_byUserId(user.id)

    exercise_muscle_contributions =
      Repo.all(
        from em in Crohnjobs.Exercises.ExerciseMuscleContribution,
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

      <div class="absolute inset-0 bg-[radial-gradient(circle_at_top,_rgba(99,102,241,0.08),_transparent_60%)]"></div>
      <div class="relative px-6 py-7 sm:px-8">
        <div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <p class="text-xs font-semibold uppercase tracking-[0.35em] text-slate-400">
              Training analytics
            </p>
            <h1 class="text-2xl font-semibold text-slate-900 sm:text-3xl">Exercise Volume</h1>
            <p class="mt-1 max-w-2xl text-sm text-slate-600">
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

      <div class="relative overflow-hidden border-t border-slate-200">
        <table class="w-full text-sm">
          <thead class="bg-slate-50/80 text-[0.7rem] uppercase tracking-[0.2em] text-slate-400">
            <tr>
              <th class="text-left py-3 px-6 font-semibold">Exercise</th>
              <th class="text-left py-3 px-6 font-semibold">Muscle</th>
              <th class="text-left py-3 px-6 font-semibold">Role</th>
              <th class="text-left py-3 px-6 font-semibold">Multiplier</th>
              <th class="text-right py-3 px-6 font-semibold">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-100">
            <%= for emc <- @exerciseMuscleContributions do %>
              <tr class="transition hover:bg-slate-50">
                <td class="px-6 py-3 font-medium text-slate-900"><%= emc.exercise.name %></td>
                <td class="px-6 py-3 text-slate-600"><%= emc.muscle.name %></td>
                <td class="px-6 py-3">
                  <span class="inline-flex items-center rounded-full px-2.5 py-1 text-xs font-semibold capitalize">
                    <%= emc.role %>
                  </span>
                </td>
                <td class="px-6 py-3 text-slate-700"><%= emc.multiplier %></td>
                <td class="px-6 py-3 text-right">
                  <%= if emc.role != "primary" do %>
                    <button
                      type="button"
                      phx-click="edit_multiplier"
                      phx-value-id={emc.id}
                      class="inline-flex items-center gap-2 rounded-full bg-slate-900 px-3 py-1.5 text-xs font-semibold text-white shadow-sm transition hover:bg-slate-800"
                    >
                      Edit
                    </button>
                  <% else %>
                    <span class="text-xs text-slate-400">Primary</span>
                  <% end %>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>


    <%= if @show_edit_dialog do %>
      <div class="fixed inset-0 z-50 flex items-center justify-center px-4" phx-click="close_edit_dialog" phx-window-keydown="close_edit_dialog" phx-key="escape">
        <div class="absolute inset-0 bg-slate-900/60" aria-hidden="true"></div>
        <div class="relative bg-white rounded-2xl shadow-2xl w-full max-w-md p-6" phx-click="stop_propagation">
          <div class="flex items-start justify-between gap-3">
            <div>
              <p class="text-xs uppercase tracking-[0.2em] text-slate-400">Edit</p>
              <h2 class="text-xl font-semibold text-slate-900">Edit Multiplier</h2>
              <p class="text-sm text-slate-500">
                Adjust the multiplier for this exercise contribution.
              </p>
            </div>
            <button
              phx-click="close_edit_dialog"
              aria-label="Close"
              class="text-slate-400 hover:text-slate-600"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-5 w-5"
                viewBox="0 0 20 20"
                fill="currentColor"
              >
                <path
                  fill-rule="evenodd"
                  d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
                  clip-rule="evenodd"
                />
              </svg>
            </button>
          </div>

          <%= if @editing_contribution do %>
            <.form phx-submit="save_multiplier" for={@edit_form} class="mt-5 space-y-4">
              <.input type="hidden" field={@edit_form[:id]} />
              <div class="space-y-2">
                <label class="block text-sm font-medium text-slate-700">Exercise</label>
                <div class="text-sm text-slate-900 font-medium">
                  <%= @editing_contribution.exercise.name %>
                </div>
              </div>
              <div class="space-y-2">
                <label class="block text-sm font-medium text-slate-700">Muscle</label>
                <div class="text-sm text-slate-900 font-medium">
                  <%= @editing_contribution.muscle.name %>
                </div>
              </div>
              <div class="space-y-2">
                <label class="block text-sm font-medium text-slate-700">Role</label>
                <div class="text-sm text-slate-900 font-medium"><%= @editing_contribution.role %></div>
              </div>
              <.input
                type="number"
                step="0.1"
                field={@edit_form[:multiplier]}
                label="Multiplier"
                placeholder="Enter multiplier value"
                required
              />

              <div class="rounded-lg border border-blue-200 bg-blue-50 px-3 py-2">
                <p class="text-xs font-semibold text-blue-700 mb-1">Calculation Example:</p>
                <p class="text-xs text-blue-800">
                  With multiplier <span class="font-semibold"><%= @editing_contribution.multiplier %></span>:
                  1 set = <%= @editing_contribution.multiplier %> set(s) of volume
                </p>
                <p class="text-xs text-blue-800 mt-1">
                  3 sets = <%= Float.round(@editing_contribution.multiplier * 3, 2) %> set(s) of volume
                </p>
              </div>

              <div class="flex items-center justify-end gap-3 pt-2">
                <button
                  type="button"
                  phx-click="close_edit_dialog"
                  class="px-4 py-2 rounded-lg bg-slate-100 text-slate-700 hover:bg-slate-200"
                >
                  Cancel
                </button>
                <.button class="bg-emerald-600 hover:bg-emerald-700 px-4 py-2 rounded-lg">
                  Save changes
                </.button>
              </div>
            </.form>
          <% end %>
        </div>
      </div>
    <% end %>
    """
  end

  def handle_event("edit_multiplier", %{"id" => id}, socket) do
    contribution =
      Enum.find(socket.assigns.exerciseMuscleContributions, &(&1.id == String.to_integer(id)))

    if contribution do
      changeset = Crohnjobs.Exercises.ExerciseMuscleContribution.changeset(contribution, %{})

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

      case Crohnjobs.Exercises.update_exercise_muscle_contribution(contribution, attrs) do
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
