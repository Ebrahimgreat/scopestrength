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

defmodule ScopestrengthWeb.ProgrammeShow do
  use ScopestrengthWeb, :live_view

  alias Scopestrength.DownloadProgramme
  alias Scopestrength.Programmes
  alias Scopestrength.Programmes.Programme
  alias Scopestrength.Repo
  alias Scopestrength.Trainers
  alias Scopestrength.Clients
  alias Scopestrength.ClientProgressions
  alias Scopestrength.Progression

  def handle_event("deleteTemplate", params, socket) do
    id = ScopestrengthWeb.Params.to_integer(params["id"])

    belongs_to_this_programme? =
      Enum.any?(socket.assigns.programme.data.programmeTemplates, &(&1.id == id))

    if belongs_to_this_programme? do
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
    else
      {:noreply, socket |> put_flash(:error, "Template not found")}
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

      "progression_method" ->
        method = params["programme"]["progression_method"]
        Programmes.update_programme(socket.assigns.programme.data, %{progression_method: method})

        programme = %{socket.assigns.programme.data | progression_method: method}
        my_programme = Programmes.change_programme(programme) |> to_form()

        {:noreply,
         socket
         |> put_flash(:info, "Progression Method Updated")
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

  def handle_event("assignClient", %{"client_id" => ""}, socket) do
    {:noreply, socket |> put_flash(:error, "Pick a client first")}
  end

  def handle_event("assignClient", %{"client_id" => client_id}, socket) do
    client_id = String.to_integer(client_id)

    programme_id = String.to_integer(socket.assigns.programmeId)

    case Programmes.assign_client_to_programme(programme_id, client_id) do
      {:ok, _programme_user} ->
        {:ok, seeded} =
          ClientProgressions.seed_from_programme(client_id, socket.assigns.programme.data)

        notify_client(socket, client_id, "programme_assigned")

        {:noreply,
         socket
         |> assign_clients()
         |> put_flash(:info, "Programme assigned to client (#{seeded} progressions seeded)")}

      {:error, _changeset} ->
        {:noreply, socket |> put_flash(:error, "Failed to assign programme")}
    end
  end

  def handle_event("unassignClient", %{"client_id" => client_id, "name" => name}, socket) do
    {:noreply, assign(socket, unassign_confirm: {String.to_integer(client_id), name})}
  end

  def handle_event("cancel_unassign", _params, socket) do
    {:noreply, assign(socket, unassign_confirm: nil)}
  end

  def handle_event("confirm_unassign", _params, socket) do
    {client_id, _name} = socket.assigns.unassign_confirm
    programme_id = String.to_integer(socket.assigns.programmeId)

    case Programmes.unassign_client_from_programme(programme_id, client_id) do
      {:ok, 0} ->
        {:noreply,
         socket
         |> assign(unassign_confirm: nil)
         |> put_flash(:error, "That client is not on this programme")}

      {:ok, _count} ->
        notify_client(socket, client_id, "programme_unenrolled")

        {:noreply,
         socket
         |> assign_clients()
         |> assign(unassign_confirm: nil)
         |> put_flash(:info, "Client removed from programme")}
    end
  end

  defp notify_client(socket, client_id, type) do
    programme = socket.assigns.programme.data
    trainer_user = socket.assigns.current_user

    case Scopestrength.Notifications.create_notification(%{
           actor_id: trainer_user.id,
           actor_type: "trainer",
           recipient_id: client_id,
           recipient_type: "client",
           type: type,
           data: %{
             programme_id: programme.id,
             programme_name: programme.name,
             trainer_name: trainer_user.name
           }
         }) do
      {:ok, notification} ->
        Phoenix.PubSub.broadcast(
          Scopestrength.PubSub,
          "notifications:client:#{client_id}",
          {:notification, notification}
        )

      {:error, _changeset} ->
        :ok
    end
  end

  defp assign_clients(socket) do
    assigned = Programmes.assigned_client_ids(String.to_integer(socket.assigns.programmeId))

    {already, available} =
      socket.assigns.trainer_id
      |> Clients.get_clients_for_trainer()
      |> Enum.split_with(&MapSet.member?(assigned, &1.id))

    assign(socket,
      clients: Enum.map(available, &{&1.user.name, &1.id}),
      assigned_clients: Enum.map(already, &{&1.user.name, &1.id})
    )
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

            muscle_volume = Programmes.calculate_programme_volume(programme)

            trainer = Trainers.get_trainer_byUserId(user.id)

            {:ok,
             socket
             |> assign(
               programme: my_programme,
               programmeId: id,
               report: false,
               muscle_volume: muscle_volume,
               trainer_id: trainer.id,
               unassign_confirm: nil
             )
             |> assign_clients()}

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
        <label class="mb-1 block text-xs uppercase tracking-widest text-dim">Progression</label>
        <.input type="select" field={@programme[:progression_method]} options={Progression.all()} />


      </.form>

      <div class="mt-8 border-t border-line pt-6">
        <label class="mb-1 block text-xs uppercase tracking-widest text-dim">Assign to client</label>

        <div :if={@assigned_clients != []} class="mb-3 flex flex-wrap items-center gap-2">
          <span class="text-xs text-dim">Already assigned:</span>
          <span
            :for={{name, id} <- @assigned_clients}
            class="inline-flex items-center gap-1 rounded-full border border-primary/40 py-0.5 pl-2.5 pr-1 text-xs text-primary"
          >
            <.icon name="hero-check" class="h-3 w-3" />
            <%= name %>
            <button
              type="button"
              phx-click="unassignClient"
              phx-value-client_id={id}
              phx-value-name={name}
              class="ml-0.5 rounded-full p-0.5 text-primary/60 transition-colors hover:bg-primary/10 hover:text-danger"
              aria-label={"Remove #{name} from this programme"}
            >
              <.icon name="hero-x-mark" class="h-3 w-3" />
            </button>
          </span>
        </div>

        <%= cond do %>
          <% @clients == [] and @assigned_clients != [] -> %>
            <p class="text-sm text-dim">Every one of your clients is on this programme.</p>
          <% @clients == [] -> %>
            <p class="text-sm text-dim">You have no clients to assign this programme to.</p>
          <% true -> %>
            <form phx-submit="assignClient" class="flex flex-wrap items-center gap-3">
              <select
                name="client_id"
                class="min-w-48 flex-1 rounded-md border-line bg-muted px-3 py-2.5 text-sm text-foreground focus:border-primary focus:ring-0"
              >
                <option value="">Select a client</option>
                <%= Phoenix.HTML.Form.options_for_select(@clients, nil) %>
              </select>
              <.button type="submit">Assign</.button>
            </form>
        <% end %>
      </div>

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

            <.confirm
              id={"delete-template-#{template.id}"}
              title="Delete Template"
              message={"Are you sure you want to delete #{template.name}? This action cannot be undone."}
              confirm_label="Delete"
              on_confirm={JS.push("deleteTemplate", value: %{id: template.id})}
              aria-label={"Delete #{template.name}"}
              class="relative z-10 shrink-0 rounded-md p-1.5 text-dim opacity-0 transition hover:bg-danger/10 hover:text-danger focus:opacity-100 group-hover:opacity-100"
            >
              <.icon name="hero-trash" class="h-4 w-4" />
            </.confirm>
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

      <div :if={@unassign_confirm} class="fixed inset-0 z-50 overflow-y-auto">
        <div class="absolute inset-0 bg-black/70" phx-click="cancel_unassign" aria-hidden="true"></div>
        <div class="relative flex min-h-full items-center justify-center p-4">
          <div
            role="dialog"
            aria-modal="true"
            class="w-full max-w-sm rounded-xl border border-line bg-card p-6 shadow-2xl"
          >
            <h3 class="font-display text-xl font-bold uppercase tracking-wide text-foreground">
              Remove Client
            </h3>
            <p class="mt-2 text-sm text-dim">
              Remove <span class="font-medium text-foreground"><%= elem(@unassign_confirm, 1) %></span>
              from this programme? They will be left with no active programme until you assign another.
            </p>
            <div class="mt-6 flex items-center justify-end gap-3">
              <button
                type="button"
                phx-click="cancel_unassign"
                class="rounded-md px-4 py-2 text-sm font-medium text-dim transition hover:text-foreground"
              >
                Cancel
              </button>
              <button
                type="button"
                phx-click="confirm_unassign"
                class="rounded-md bg-danger px-4 py-2 text-sm font-semibold text-foreground transition hover:opacity-90"
              >
                Remove
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp vol_pct(_value, max) when max <= 0, do: 0
  defp vol_pct(value, max), do: Float.round(value / max * 100, 2)
end
