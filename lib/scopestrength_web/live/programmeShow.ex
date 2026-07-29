defmodule ScopestrengthWeb.ProgrammeShow do
  use ScopestrengthWeb, :live_view

  alias Scopestrength.DownloadProgramme
  alias Scopestrength.Programmes
  alias Scopestrength.Programmes.Programme
  alias Scopestrength.Repo
  alias Scopestrength.Trainers

  def handle_event("deleteTemplate", params, socket) do
    id = String.to_integer(params["id"])
    programme_template = Programmes.get_programme_template!(id)

    case Programmes.delete_programme_template(programme_template) do
      {:ok, _template} ->
        programme = %{
          socket.assigns.programme.data
          | programmeTemplates:
              Enum.reject(socket.assigns.programme.data.programmeTemplates, &(&1.id == id))
        }

        updated_form = Programmes.change_programme(programme) |> to_form()

        {:noreply,
         socket
         |> put_flash(:info, "Template Deleted")
         |> assign(:programme, updated_form)}
    end
  end

  def handle_event("downloadProgramme", _, socket) do
    programme =
      Repo.get!(Programme, socket.assigns.programmeId)
      |> Repo.preload(programmeTemplates: [programmeDetails: :exercise])

    DownloadProgramme.downloadProgramme(%{programme: programme})
    {:noreply, assign(socket, report: true)}
  end

  def handle_event("updateForm", params, socket) do
    target = Enum.at(params["_target"], 1)

    case target do
      "name" ->
        Programmes.update_programme(socket.assigns.programme.data, %{name: params["programme"]["name"]})
        programme = %{socket.assigns.programme.data | name: params["programme"]["name"]}
        my_programme = Programmes.change_programme(programme) |> to_form()

        {:noreply,
         socket
         |> put_flash(:info, "Programme Name Updated")
         |> assign(:programme, my_programme)}

      "description" ->
        Programmes.update_programme(socket.assigns.programme.data, %{
          description: params["programme"]["description"]
        })

        programme = %{socket.assigns.programme.data | description: params["programme"]["description"]}
        my_programme = Programmes.change_programme(programme) |> to_form()

        {:noreply,
         socket
         |> put_flash(:info, "Programme Description Updated")
         |> assign(:programme, my_programme)}

      _ ->
        {:noreply, put_flash(socket, :error, "Something Happened")}
    end
  end

  def handle_event("addTemplate", _params, socket) do
    id = socket.assigns.programme.data.id
    new_template = %{name: "Untitled", programme_id: id}
    programme_templates = socket.assigns.programme.data.programmeTemplates

    case Programmes.create_programme_template(new_template) do
      {:ok, template} ->
        programme = %{
          socket.assigns.programme.data
          | programmeTemplates: programme_templates ++ [template]
        }

        updated_form = Programmes.change_programme(programme) |> to_form()

        {:noreply,
         socket
         |> put_flash(:info, "Template Added")
         |> assign(:programme, updated_form)}

      _ ->
        {:noreply, socket |> put_flash(:error, "An error has occured")}
    end
  end

  @spec mount(map(), any(), any()) :: {:ok, any()}
  def mount(%{"id" => id}, _session, socket) do
    user = socket.assigns.current_user

    case Programmes.get_programme_with_template(id) do
      nil ->
        {:ok, socket |> put_flash(:error, "Programme not found") |> redirect(to: "/programmes")}

      programme ->
        case programme.user_id == user.id do
          true ->
            my_programme = Programmes.change_programme(programme) |> to_form()

            # Calculate total volume across all templates
            muscle_volume = Programmes.calculate_programme_volume(programme)

            {:ok, assign(socket,
              programme: my_programme,
              programmeId: id,
              report: false,
              muscle_volume: muscle_volume
            )}

          false ->
            {:ok, socket |> put_flash(:error, "Programme not found") |> redirect(to: "/programmes")}
        end
    end
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-5xl">
      <% template_count = length(@programme.data.programmeTemplates) %>

      <div class="flex flex-wrap items-end justify-between gap-4">
        <div class="min-w-0">
          <.link
            navigate={~p"/trainer/programmes"}
            class="inline-flex items-center gap-1 text-xs font-medium uppercase tracking-widest text-dim transition hover:text-foreground"
          >
            <.icon name="hero-chevron-left" class="h-3 w-3" /> Programmes
          </.link>
          <h1 class="mt-1 font-display text-5xl font-bold uppercase tracking-wide text-foreground">
            <%= @programme[:name].value %>
          </h1>
        </div>

        <div class="flex shrink-0 flex-wrap gap-2">
          <%= if @report == false do %>
            <button
              type="button"
              phx-click="downloadProgramme"
              class="rounded-md border border-line px-3 py-2 text-sm font-medium text-dim transition hover:border-dim hover:text-foreground"
            >
              Generate report
            </button>
          <% else %>
            <a
              href="/download/workout"
              class="rounded-md border border-primary/40 px-3 py-2 text-sm font-medium text-primary transition hover:opacity-80"
            >
              Download report
            </a>
          <% end %>
          <.button type="button" phx-click="addTemplate">
            <span class="inline-flex items-center gap-2">
              <.icon name="hero-plus" class="h-4 w-4" /> Add template
            </span>
          </.button>
        </div>
      </div>

      <.form phx-change="updateForm" for={@programme} class="mt-8 space-y-4">
        <div>
          <label class="mb-1 block text-xs uppercase tracking-widest text-dim">Programme name</label>
          <input
            type="text"
            name={@programme[:name].name}
            value={@programme[:name].value}
            phx-debounce="600"
            placeholder="Enter programme name"
            class="w-full rounded-md border-line bg-muted px-3 py-2.5 text-sm text-foreground placeholder:text-faint focus:border-primary focus:ring-0"
          />
        </div>
        <div>
          <label class="mb-1 block text-xs uppercase tracking-widest text-dim">Description</label>
          <textarea
            name={@programme[:description].name}
            rows="3"
            phx-debounce="700"
            placeholder="Describe your programme focus, split, or progression notes"
            class="w-full rounded-md border-line bg-muted px-3 py-2.5 text-sm text-foreground placeholder:text-faint focus:border-primary focus:ring-0"
          ><%= Phoenix.HTML.Form.normalize_value("textarea", @programme[:description].value) %></textarea>
        </div>
      </.form>

      <div :if={map_size(@muscle_volume) > 0} class="mt-10 border-t border-line pt-6">
        <div class="flex items-baseline justify-between gap-3">
          <h2 class="text-sm font-semibold text-foreground">Programme Volume</h2>
          <span class="text-xs text-dim">Combined across all templates</span>
        </div>

        <% volume_max =
          @muscle_volume |> Enum.map(fn {_m, v} -> v.effective end) |> Enum.max(fn -> 0.0 end) %>
        <div class="mt-4 space-y-2.5">
          <%= for {muscle_group, volumes} <- Enum.sort_by(@muscle_volume, fn {_m, v} -> v.effective end, :desc) do %>
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
                    style={"width: #{vol_pct(volumes.direct, volume_max)}%"}
                  >
                  </div>
                  <div
                    class="h-full bg-primary/30"
                    style={"width: #{vol_pct(indirect, volume_max)}%"}
                  >
                  </div>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <div class="mt-10 border-t border-line pt-6">
        <div class="flex items-baseline justify-between gap-3">
          <h2 class="text-sm font-semibold text-foreground">Templates</h2>
          <span class="num text-xs text-dim"><%= template_count %></span>
        </div>

        <div :if={template_count > 0} class="mt-4 overflow-hidden rounded-xl border border-line bg-card">
          <div
            :for={{template, index} <- Enum.with_index(@programme.data.programmeTemplates)}
            class="group relative flex items-center gap-4 border-b border-line/60 px-5 py-4 transition last:border-0 hover:bg-secondary/50"
          >
            <span class="num w-6 shrink-0 text-sm text-faint"><%= index + 1 %></span>

            <.link
              navigate={~p"/trainer/programmes/#{@programmeId}/template/#{template.id}"}
              class="min-w-0 flex-1 after:absolute after:inset-0"
            >
              <span class="truncate font-medium text-foreground"><%= template.name %></span>
            </.link>

            <button
              type="button"
              phx-click="deleteTemplate"
              phx-value-id={template.id}
              data-confirm="Are you sure you want to delete this template?"
              aria-label={"Delete #{template.name}"}
              class="relative z-10 shrink-0 rounded-md p-1.5 text-dim opacity-0 transition hover:bg-danger/10 hover:text-danger focus:opacity-100 group-hover:opacity-100"
            >
              <.icon name="hero-trash" class="h-4 w-4" />
            </button>
            <.icon name="hero-chevron-right" class="h-4 w-4 shrink-0 text-faint" />
          </div>
        </div>

        <div
          :if={template_count == 0}
          class="mt-4 rounded-xl border border-dashed border-line px-6 py-12 text-center"
        >
          <p class="text-sm font-medium text-foreground">No templates yet</p>
          <p class="mx-auto mt-1 max-w-sm text-sm text-dim">
            Add your first workout template to start structuring this programme.
          </p>
          <div class="mt-6">
            <.button type="button" phx-click="addTemplate">Add first template</.button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Bar segment width, guarding an empty programme.
  defp vol_pct(_value, max) when max <= 0, do: 0
  defp vol_pct(value, max), do: Float.round(value / max * 100, 2)
end
