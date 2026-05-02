defmodule ScopestrengthWeb.Client.ProgrammeShow do
  use ScopestrengthWeb, :live_view

  alias Scopestrength.DownloadProgramme
  alias Scopestrength.Programmes
  alias Scopestrength.Programmes.Programme
  alias Scopestrength.Repo

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

  def mount(%{"id" => id}, _session, socket) do
    user = socket.assigns.current_user

    case Programmes.get_programme_with_template(id) do
      nil ->
        {:ok, socket |> put_flash(:error, "Programme not found") |> redirect(to: "/client/programmes")}

      programme ->
        case programme.user_id == user.id do
          true ->
            my_programme = Programmes.change_programme(programme) |> to_form()
            muscle_volume = Programmes.calculate_programme_volume(programme)

            {:ok, assign(socket,
              programme: my_programme,
              programmeId: id,
              report: false,
              muscle_volume: muscle_volume
            )}

          false ->
            {:ok, socket |> put_flash(:error, "Programme not found") |> redirect(to: "/client/programmes")}
        end
    end
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-b from-slate-50 via-white to-white">
      <div class="mx-auto w-full max-w-6xl px-4 py-8 sm:px-6 lg:px-8 lg:py-10">
        <% template_count = length(@programme.data.programmeTemplates) %>
        <div class="space-y-8">
          <section class="relative overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
            <div class="absolute -right-20 -top-24 h-56 w-56 rounded-full bg-emerald-100/70 blur-2xl"></div>
            <div class="relative flex flex-col gap-6 p-6 sm:p-8">
              <div class="flex flex-wrap items-center gap-2 text-xs font-medium uppercase tracking-[0.16em] text-slate-500">
                <.link navigate={~p"/client/programmes"} class="hover:text-slate-700 transition-colors">
                  Programmes
                </.link>
                <span>/</span>
                <span class="text-slate-700">Editor</span>
              </div>

              <div class="flex flex-col gap-6 lg:flex-row lg:items-end lg:justify-between">
                <div>
                  <h1 class="text-3xl font-semibold tracking-tight text-slate-900 sm:text-4xl">
                    <%= @programme[:name].value %>
                  </h1>
                  <p class="mt-2 max-w-2xl text-sm text-slate-600 sm:text-base">
                    Refine programme details, build templates, and export a workout report when ready.
                  </p>
                </div>

                <div class="flex flex-wrap gap-3">
                  <button
                    type="button"
                    phx-click="addTemplate"
                    class="inline-flex items-center justify-center rounded-full bg-slate-900 px-5 py-2.5 text-sm font-semibold text-white shadow-sm transition hover:bg-slate-700"
                  >
                    Add template
                  </button>
                  <%= if @report == false do %>
                    <button
                      type="button"
                      phx-click="downloadProgramme"
                      class="inline-flex items-center justify-center rounded-full border border-slate-300 bg-white px-5 py-2.5 text-sm font-semibold text-slate-700 shadow-sm transition hover:border-slate-400 hover:bg-slate-50"
                    >
                      Generate report
                    </button>
                  <% else %>
                    <a
                      href="/download/workout"
                      class="inline-flex items-center justify-center rounded-full border border-emerald-200 bg-emerald-50 px-5 py-2.5 text-sm font-semibold text-emerald-700 transition hover:bg-emerald-100"
                    >
                      Download report
                    </a>
                  <% end %>
                </div>
              </div>

              <div class="grid gap-3 sm:grid-cols-2 lg:max-w-xl">
                <div class="rounded-xl border border-slate-200 bg-slate-50 p-4">
                  <p class="text-xs uppercase tracking-wide text-slate-500">Templates</p>
                  <p class="mt-1 text-2xl font-semibold text-slate-900"><%= template_count %></p>
                </div>
                <div class="rounded-xl border border-slate-200 bg-slate-50 p-4">
                  <p class="text-xs uppercase tracking-wide text-slate-500">Report</p>
                  <p class="mt-1 text-sm font-semibold text-slate-900">
                    <%= if @report, do: "Ready to download", else: "Not generated yet" %>
                  </p>
                </div>
              </div>
            </div>
          </section>

          <%= if map_size(@muscle_volume) > 0 do %>
            <section class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
              <h2 class="text-lg font-semibold text-slate-900 mb-4">Total Programme Volume</h2>
              <p class="text-sm text-slate-600 mb-5">Combined volume across all templates</p>

              <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-3">
                <%= for {muscle_group, volumes} <- @muscle_volume do %>
                  <div class="bg-gradient-to-br from-indigo-50 to-white border border-indigo-100 rounded-lg px-3 py-2.5">
                    <div class="flex flex-col gap-2">
                      <span class="text-xs font-semibold text-slate-700 truncate">
                        <%= muscle_group %>
                      </span>

                      <div class="flex items-center justify-between text-[11px] text-slate-500">
                        <span>Direct</span>
                        <span class="inline-flex items-center justify-center px-2 py-0.5 bg-indigo-600 text-white text-xs font-semibold rounded-full">
                          <%= Float.round(volumes.direct) %>
                        </span>
                      </div>

                      <div class="flex items-center justify-between text-[11px] text-slate-500">
                        <span>Effective</span>
                        <span class="inline-flex items-center justify-center px-2 py-0.5 bg-indigo-100 text-indigo-700 text-xs font-semibold rounded-full">
                          <%= Float.round(volumes.effective, 1) %>
                        </span>
                      </div>
                    </div>
                  </div>
                <% end %>
              </div>
            </section>
          <% end %>

          <section class="grid gap-6 lg:grid-cols-[minmax(0,1fr)_minmax(0,1.4fr)]">
            <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
              <h2 class="text-lg font-semibold text-slate-900">Programme Details</h2>
              <p class="mt-1 text-sm text-slate-600">Changes are saved automatically.</p>

              <.form phx-change="updateForm" for={@programme} class="mt-5 space-y-4">
                <.input
                  field={@programme[:name]}
                  type="text"
                  label="Programme name"
                  phx-debounce="600"
                  class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm shadow-sm focus:border-emerald-500 focus:ring-emerald-500"
                  placeholder="Enter programme name"
                />
                <.input
                  field={@programme[:description]}
                  type="textarea"
                  label="Description"
                  phx-debounce="700"
                  rows="4"
                  class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm shadow-sm focus:border-emerald-500 focus:ring-emerald-500"
                  placeholder="Describe your programme focus, split, or progression notes"
                />
              </.form>
            </div>

            <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
              <div class="flex items-center justify-between gap-4">
                <h2 class="text-lg font-semibold text-slate-900">Workout Templates</h2>
                <span class="inline-flex items-center rounded-full bg-slate-100 px-3 py-1 text-xs font-medium text-slate-700">
                  <%= template_count %> template<%= if template_count != 1, do: "s" %>
                </span>
              </div>

              <%= if template_count > 0 do %>
                <div class="mt-5 space-y-3">
                  <%= for {template, index} <- Enum.with_index(@programme.data.programmeTemplates) do %>
                    <div class="rounded-xl border border-slate-200 bg-white p-4 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md">
                      <div class="flex flex-wrap items-start justify-between gap-3">
                        <div class="space-y-1">
                          <p class="text-xs font-medium uppercase tracking-[0.16em] text-slate-400">
                            Template <%= index + 1 %>
                          </p>
                          <p class="text-base font-semibold text-slate-900"><%= template.name %></p>
                        </div>

                        <div class="flex items-center gap-2">
                          <.link
                            navigate={~p"/client/programmes/#{@programmeId}/template/#{template.id}"}
                            class="inline-flex items-center rounded-full border border-slate-200 bg-white px-3 py-1.5 text-xs font-semibold text-slate-700 transition hover:border-slate-300 hover:bg-slate-50"
                          >
                            Open
                          </.link>
                          <button
                            type="button"
                            phx-click="deleteTemplate"
                            phx-value-id={template.id}
                            data-confirm="Are you sure you want to delete this template?"
                            class="inline-flex items-center rounded-full border border-rose-200 bg-rose-50 px-3 py-1.5 text-xs font-semibold text-rose-700 transition hover:border-rose-300 hover:bg-rose-100"
                          >
                            Delete
                          </button>
                        </div>
                      </div>
                    </div>
                  <% end %>
                </div>
              <% else %>
                <div class="mt-5 rounded-xl border border-dashed border-slate-300 bg-slate-50 px-4 py-10 text-center">
                  <p class="text-sm font-medium text-slate-700">No templates yet</p>
                  <p class="mt-1 text-sm text-slate-500">
                    Add your first workout template to start structuring this programme.
                  </p>
                  <button
                    type="button"
                    phx-click="addTemplate"
                    class="mt-4 inline-flex items-center rounded-full bg-slate-900 px-4 py-2 text-xs font-semibold text-white transition hover:bg-slate-700"
                  >
                    Add first template
                  </button>
                </div>
              <% end %>
            </div>
          </section>
        </div>
      </div>
    </div>
    """
  end
end
