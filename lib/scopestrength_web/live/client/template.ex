defmodule ScopestrengthWeb.Client.Template do
  alias Scopestrength.Exercises.ExerciseMuscleContribution
  alias Scopestrength.Exercise
  use ScopestrengthWeb, :live_view
  alias Scopestrength.Programmes
  alias Scopestrength.Programmes.Programme
  alias Scopestrength.Programmes.ProgrammeTemplate
  alias Scopestrength.Repo
  import Ecto.Query

  def handle_event("updateForm", params, socket) do
    name = params["programme_template"]["name"]
    programmeTemplate = socket.assigns.template.data
    case Programmes.update_programme_template(programmeTemplate, %{name: name}) do
      {:ok, _programme} ->
        template = %{programmeTemplate | name: name}
        templateForm = Programmes.change_programme_template(template) |> to_form()
        {:noreply, socket |> put_flash(:info, "Template Updated") |> assign(:template, templateForm)}

      _ -> {:noreply, socket |> put_flash(:error, "Something Happened")}
    end
  end

  def mount(params, _session, socket) do
    user = socket.assigns.current_user
    template_id = String.to_integer(params["template_id"])

    case Repo.get(ProgrammeTemplate, template_id) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Template not found")
         |> redirect(to: "/client/programmes")}

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

            muscleContributions = Repo.all(from c in ExerciseMuscleContribution, where: c.exercise_id in ^exercise_ids) |> Repo.preload(:muscle)

            contributions_by_exercise =
              muscleContributions
              |> Enum.group_by(& &1.exercise_id)

            expanded =
              template.programmeDetails
              |> Enum.flat_map(fn detail ->
                sets = String.to_integer(detail.set)
                contributions = Map.get(contributions_by_exercise, detail.exercise_id, [])
                Enum.map(contributions, fn c ->
                  {c.muscle.name, c.role, sets * c.multiplier}
                end)
              end)

            muscle_group_frequencies =
              expanded
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
             |> redirect(to: "/client/programmes")}
        end
    end
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div class="mb-8">
        <div class="flex items-center justify-between mb-6">
          <div class="flex items-center space-x-4">
            <.link
              navigate={~p"/client/programmes/#{@template.data.programme_id}"}
              class="inline-flex items-center text-sm text-dim hover:text-foreground transition-colors duration-200"
            >
              <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
              </svg>
              Back to Programme
            </.link>
            <svg class="w-4 h-4 text-faint" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z" clip-rule="evenodd" />
            </svg>
            <h1 class="text-3xl font-bold text-foreground">
              <%= @template.data.name %>
            </h1>
          </div>
          <.link
            navigate={~p"/client/programmes/#{@template.data.programme_id}/template/#{@template.data.id}/details"}
            class="inline-flex items-center px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-foreground font-medium rounded-lg shadow-sm transition-colors duration-200"
          >
            <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
            </svg>
            View Details
          </.link>
        </div>
      </div>

      <div class="mb-8">
        <div class="bg-card rounded-lg shadow-sm border border-line p-6">
          <h2 class="text-xl font-semibold text-foreground mb-4">Template Settings</h2>
          <.form phx-submit="updateForm" for={@template} class="space-y-4">
            <div class="flex items-end space-x-4">
              <div class="flex-1">
                <.input
                  label="Template Name"
                  field={@template[:name]}
                  class="block w-full rounded-md border-line shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                  placeholder="Enter template name"
                />
              </div>
              <.button class="inline-flex items-center px-4 py-2 bg-primary hover:bg-green-700 text-foreground font-medium rounded-lg shadow-sm transition-colors duration-200">
                Update Name
              </.button>
            </div>
          </.form>
        </div>
      </div>

      <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-3">
        <%= for {muscle_group, volumes} <- @muscle_group_frequencies do %>
          <div class="bg-gradient-to-br from-indigo-50 to-white border border-indigo-100 rounded-lg px-3 py-2.5">
            <div class="flex flex-col gap-2">
              <span class="text-xs font-semibold text-foreground truncate">
                <%= muscle_group %>
              </span>
              <div class="flex items-center justify-between text-[11px] text-dim">
                <span>Direct</span>
                <span class="inline-flex items-center justify-center px-2 py-0.5 bg-indigo-600 text-foreground text-xs font-semibold rounded-full">
                  <%= Float.round(volumes.direct) %>
                </span>
              </div>
              <div class="flex items-center justify-between text-[11px] text-dim">
                <span>Effective</span>
                <span class="inline-flex items-center justify-center px-2 py-0.5 bg-indigo-100 text-indigo-700 text-xs font-semibold rounded-full">
                  <%= Float.round(volumes.effective, 1) %>
                </span>
              </div>
            </div>
          </div>
        <% end %>
      </div>

      <div class="bg-card rounded-lg shadow-sm border border-line">
        <div class="px-6 py-4 border-b border-line">
          <div class="flex items-center justify-between">
            <h2 class="text-xl font-semibold text-foreground">Programme Details</h2>
            <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
              <%= length(@template.data.programmeDetails) %> exercise<%= if length(@template.data.programmeDetails) != 1, do: "s" %>
            </span>
          </div>
        </div>

        <div class="p-6">
          <%= if length(@template.data.programmeDetails) > 0 do %>
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              <%= for {programmeDetail, index} <- Enum.with_index(@template.data.programmeDetails) do %>
                <div class="bg-gradient-to-br from-gray-50 to-white border border-line rounded-lg p-4 hover:shadow-md transition-shadow duration-200">
                  <div class="flex items-center justify-between mb-3">
                    <div class="flex items-center space-x-2">
                      <div class="w-8 h-8 bg-indigo-100 rounded-full flex items-center justify-center">
                        <span class="text-sm font-semibold text-indigo-600"><%= index + 1 %></span>
                      </div>
                      <span class="text-xs font-medium text-dim uppercase tracking-wide"><%= programmeDetail.exercise.name %></span>
                    </div>
                    <span class="text-xs font-medium text-dim uppercase tracking-wide">
                      <%= if programmeDetail.exercise.muscle, do: programmeDetail.exercise.muscle.name, else: "N/A" %>
                    </span>
                  </div>

                  <div class="space-y-3">
                    <div class="flex items-center justify-between">
                      <span class="text-sm font-medium text-dim">Sets</span>
                      <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                        <%= programmeDetail.set %>
                      </span>
                    </div>
                    <div class="flex items-center justify-between">
                      <span class="text-sm font-medium text-dim">Reps</span>
                      <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-primary/10 text-primary">
                        <%= programmeDetail.reps %>
                      </span>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          <% else %>
            <div class="text-center py-12">
              <h3 class="mt-2 text-sm font-medium text-foreground">No exercises yet</h3>
              <p class="mt-1 text-sm text-dim">Add some exercises to get started with this template.</p>
              <div class="mt-6">
                <.link
                  navigate={~p"/client/programmes/#{@template.data.programme_id}/template/#{@template.data.id}/details"}
                  class="inline-flex items-center px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-foreground font-medium rounded-lg shadow-sm transition-colors duration-200"
                >
                  Add Exercises
                </.link>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
