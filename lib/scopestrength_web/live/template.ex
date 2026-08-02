defmodule ScopestrengthWeb.Template do
alias Scopestrength.Exercises.ExerciseMuscleContribution
alias Scopestrength.Exercise
alias Scopestrength.Trainers
  use ScopestrengthWeb, :live_view
  alias Scopestrength.Programmes
  alias Scopestrength.Programmes.Programme
  alias Scopestrength.Programmes.ProgrammeTemplate
  alias Scopestrength.Repo
  import Ecto.Query

  def handle_event("updateForm", params, socket) do
    IO.inspect(params)
    name = params["programme_template"]["name"]
    programmeTemplate = socket.assigns.template.data
    case Programmes.update_programme_template(programmeTemplate, %{name: name}) do
      {:ok, _programme}->
        template = %{programmeTemplate | name: name}
        templateForm = Programmes.change_programme_template(template)|>to_form()

        {:noreply, socket|> put_flash(:info, "Template Updated")|> assign(:template, templateForm)}

        _ ->{:noreply,socket|> put_flash(:eror, "SOmething Happend")}
    end
  end
 @spec mount(nil | maybe_improper_list() | map(), any(), any()) :: {:ok, any()}
 def mount(params, session, socket) do
  user = socket.assigns.current_user
  trainer = Trainers.get_trainer_byUserId(user.id)
  template_id = String.to_integer(params["template_id"])
  programme_id = String.to_integer(params["id"])

  case Repo.get(ProgrammeTemplate, template_id) do
    nil ->
      {:ok,
       socket
       |> put_flash(:error, "Template not found")
       |> redirect(to: "/programmes")}

    template ->
      programme = Repo.get(Programme, template.programme_id)

      case programme.user_id == user.id do
        true ->
          template = Repo.preload(template, programmeDetails: [exercise: [:muscle, :equipment]])


          template_changeset = Programmes.change_programme_template(template) |> to_form()
          exercise_ids =
            template.programmeDetails
            |> Enum.map(& &1.exercise_id)
            |> Enum.uniq()
            muscleContributions = Repo.all(from c in ExerciseMuscleContribution, where: c.exercise_id in ^exercise_ids)|>Repo.preload(:muscle)

            contributions_by_exercise =
              muscleContributions
              |> Enum.group_by(& &1.exercise_id)


              expanded =
                template.programmeDetails
                |> Enum.flat_map(fn detail ->
                  sets = String.to_integer(detail.set)

                  contributions =
                    Map.get(contributions_by_exercise, detail.exercise_id, [])


                  Enum.map(contributions, fn c ->
                    {
                      c.muscle.name,
                      c.role,
                      sets * c.multiplier
                    }
                  end)
                end)


                grouped =
                  expanded
                  |> Enum.group_by(fn {muscle, role, _volume} ->
                    muscle
                  end)

                  muscle_group_frequencies =
                    grouped
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
                    IO.inspect(muscle_group_frequencies)


          {:ok,
           assign(socket,
             template: template_changeset,
             template_id: template_id,
             muscle_group_frequencies: muscle_group_frequencies
           )}

        false ->
          {:ok,
           socket
           |> put_flash(:error, "Template not found")
           |> redirect(to: "/programmes")}
      end
  end
end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-5xl">
      <div class="flex flex-wrap items-end justify-between gap-4">
        <div class="min-w-0">
          <.link
            navigate={~p"/trainer/programmes/#{@template.data.programme_id}"}
            class="inline-flex items-center gap-1 text-xs font-medium uppercase tracking-widest text-dim transition hover:text-foreground"
          >
            <.icon name="hero-chevron-left" class="h-3 w-3" /> Back to programme
          </.link>
          <h1 class="mt-1 font-display text-5xl font-bold uppercase tracking-wide text-foreground">
            <%= @template.data.name %>
          </h1>
        </div>

        <.link
          navigate={~p"/trainer/programmes/#{@template.data.programme_id}/template/#{@template.data.id}/details"}
          class="shrink-0 rounded-md bg-primary px-4 py-2 text-sm font-semibold text-primary-foreground transition hover:opacity-90"
        >
          Add exercises
        </.link>
      </div>

      <.form phx-submit="updateForm" for={@template} class="mt-8 flex flex-wrap items-end gap-3">
        <div class="min-w-0 flex-1">
          <label class="mb-1 block text-xs uppercase tracking-widest text-dim">Template name</label>
          <input
            type="text"
            name={@template[:name].name}
            value={@template[:name].value}
            placeholder="Enter template name"
            class="w-full rounded-md border-line bg-muted px-3 py-2.5 text-sm text-foreground placeholder:text-faint focus:border-primary focus:ring-0"
          />
        </div>
        <.button>Save</.button>
      </.form>

      <div :if={map_size(@muscle_group_frequencies) > 0} class="mt-10 border-t border-line pt-6">
        <div class="flex items-baseline justify-between gap-3">
          <h2 class="text-sm font-semibold text-foreground">Template Volume</h2>
          <span class="text-xs text-dim">Direct + indirect sets</span>
        </div>

        <% vol_max =
          @muscle_group_frequencies
          |> Enum.map(fn {_m, v} -> v.effective end)
          |> Enum.max(fn -> 0.0 end) %>
        <div class="mt-4 space-y-2.5">
          <%= for {muscle_group, volumes} <- Enum.sort_by(@muscle_group_frequencies, fn {_m, v} -> v.effective end, :desc) do %>
            <% indirect = max(volumes.effective - volumes.direct, 0.0) %>
            <div>
              <div class="flex items-baseline justify-between gap-3">
                <span class="truncate text-sm text-foreground"><%= muscle_group %></span>
                <span class="num shrink-0 text-xs text-dim">
                  <span class="text-foreground"><%= round(volumes.direct) %></span>
                  <span :if={indirect > 0}> + <%= round(indirect) %></span>
                </span>
              </div>
              <div class="mt-1.5 h-1.5 w-full overflow-hidden rounded-full bg-muted">
                <div class="flex h-full">
                  <div
                    class="h-full rounded-l-full bg-primary"
                    style={"width: #{tpl_pct(volumes.direct, vol_max)}%"}
                  >
                  </div>
                  <div class="h-full bg-primary/30" style={"width: #{tpl_pct(indirect, vol_max)}%"}>
                  </div>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <div class="mt-10 border-t border-line pt-6">
        <div class="flex items-baseline justify-between gap-3">
          <h2 class="text-sm font-semibold text-foreground">Exercises</h2>
          <span class="num text-xs text-dim">
            <%= length(@template.data.programmeDetails) %>
          </span>
        </div>

        <div
          :if={@template.data.programmeDetails != []}
          class="mt-4 overflow-hidden rounded-xl border border-line bg-card"
        >
          <div
            :for={{programmeDetail, index} <- Enum.with_index(@template.data.programmeDetails)}
            class="flex items-center gap-4 border-b border-line/60 px-5 py-4 last:border-0"
          >
            <span class="num w-6 shrink-0 text-sm text-faint"><%= index + 1 %></span>

            <div class="min-w-0 flex-1">
              <p class="truncate font-medium text-foreground">
                <%= programmeDetail.exercise.name %>
              </p>
              <p class="mt-0.5 text-xs text-dim">
                <%= if programmeDetail.exercise.muscle,
                  do: programmeDetail.exercise.muscle.name,
                  else: "—" %>
              </p>
            </div>

            <span class="num shrink-0 text-sm text-foreground">
              <%= programmeDetail.set %>×<%= programmeDetail.reps %>
            </span>
          </div>
        </div>

        <div
          :if={@template.data.programmeDetails == []}
          class="mt-4 rounded-xl border border-dashed border-line px-6 py-12 text-center"
        >
          <p class="text-sm font-medium text-foreground">No exercises yet</p>
          <p class="mx-auto mt-1 max-w-sm text-sm text-dim">
            Add exercises to get started with this template.
          </p>
          <div class="mt-6">
            <.link
              navigate={~p"/trainer/programmes/#{@template.data.programme_id}/template/#{@template.data.id}/details"}
              class="text-sm font-medium text-primary transition hover:opacity-80"
            >
              Add exercises →
            </.link>
          </div>
        </div>
      </div>
    </div>
    """
  end
  # Bar segment width, guarding an empty template.
  defp tpl_pct(_value, max) when max <= 0, do: 0
  defp tpl_pct(value, max), do: Float.round(value / max * 100, 2)
end
