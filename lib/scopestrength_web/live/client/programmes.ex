defmodule ScopestrengthWeb.Client.Programmes do
  alias Scopestrength.Programmes

  use ScopestrengthWeb, :live_view

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    newProgramme = Programmes.change_programme(%Programmes.Programme{}) |> to_form()

    programmes =
      Programmes.list_programme()
      |> Enum.filter(&(&1.user_id == user.id))

    {:ok, assign(socket, user_id: user.id, programmes: programmes, name: user.name, newProgramme: newProgramme, delete_confirm_id: nil)}
  end

  def handle_event("addNewProgramme", _params, socket) do
    newProgramme = %{name: "Untitled", description: "untitled", user_id: socket.assigns.user_id}
    case Programmes.create_programme(newProgramme) do
      {:ok, programme} -> {:noreply, update(socket, :programmes, fn programmes -> [programme | programmes] end)}
      _ -> {:noreply, socket |> put_flash(:error, "An error has occurred")}
    end
  end

  def handle_event("deleteProgramme", %{"id" => id}, socket) do
    id = String.to_integer(id)
    {:noreply, assign(socket, delete_confirm_id: id)}
  end

  def handle_event("cancel_delete", _params, socket) do
    {:noreply, assign(socket, delete_confirm_id: nil)}
  end

  def handle_event("confirm_delete", _params, socket) do
    id = socket.assigns.delete_confirm_id

    programme = Programmes.get_programme!(id)
    case Programmes.delete_programme(programme) do
      {:ok, _programme} ->
        programmes = Enum.reject(socket.assigns.programmes, &(&1.id == id))
        {:noreply, socket |> put_flash(:info, "Programme Deleted") |> assign(programmes: programmes, delete_confirm_id: nil)}
      _ -> {:noreply, socket |> put_flash(:error, "An error has occurred") |> assign(delete_confirm_id: nil)}
    end
  end

  def handle_event("duplicateProgramme", %{"id" => id}, socket) do
    id = String.to_integer(id)

    case Programmes.clone_programme(id) do
      {:ok, new_programme} ->
        {:noreply,
         update(socket, :programmes, fn programmes -> [new_programme | programmes] end)
         |> put_flash(:info, "Programme duplicated")}

      {:error, _} ->
        {:noreply, socket |> put_flash(:error, "Failed to duplicate programme")}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-5xl">
      <div class="flex flex-wrap items-end justify-between gap-4">
        <div>
          <p class="text-xs font-medium uppercase tracking-widest text-dim">Training</p>
          <h1 class="mt-1 font-display text-5xl font-bold uppercase tracking-wide text-foreground">
            My Programmes
          </h1>
          <p class="mt-2 max-w-xl text-sm text-dim">
            Create and manage your training programmes, <%= @name %>
          </p>
        </div>

        <.button type="button" phx-click="addNewProgramme" class="shrink-0">
          <span class="inline-flex items-center gap-2">
            <.icon name="hero-plus" class="h-4 w-4" /> New programme
          </span>
        </.button>
      </div>

      <div
        :if={@programmes == []}
        class="mt-8 rounded-xl border border-dashed border-line px-6 py-16 text-center"
      >
        <h3 class="font-display text-xl font-bold uppercase tracking-wide text-foreground">
          No programmes yet
        </h3>
        <p class="mx-auto mt-2 max-w-sm text-sm text-dim">
          Get started by creating your first training programme.
        </p>
        <div class="mt-6">
          <.button type="button" phx-click="addNewProgramme">Create your first programme</.button>
        </div>
      </div>

      <div :if={@programmes != []} class="mt-8 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
        <div
          :for={programme <- @programmes}
          class="group relative flex flex-col rounded-xl border border-line bg-card p-5 transition hover:border-dim"
        >
          <%!-- Stretched link covers the card; the action row sits above it. --%>
          <.link
            navigate={~p"/client/programmes/#{programme.id}"}
            class="after:absolute after:inset-0 after:rounded-xl"
          >
            <h3 class="font-semibold leading-snug text-foreground"><%= programme.name %></h3>
          </.link>

          <p class="mt-2 line-clamp-2 min-h-[2.5rem] text-sm text-dim">
            <%= if programme.description && programme.description != "" do %>
              <%= programme.description %>
            <% else %>
              No description
            <% end %>
          </p>

          <div class="relative z-10 mt-4 flex items-center gap-1 border-t border-line pt-3">
            <button
              type="button"
              phx-click="duplicateProgramme"
              phx-value-id={programme.id}
              class="rounded-md px-2 py-1 text-xs font-medium text-dim transition hover:bg-secondary hover:text-foreground"
            >
              Duplicate
            </button>
            <button
              type="button"
              phx-click="deleteProgramme"
              phx-value-id={programme.id}
              class="rounded-md px-2 py-1 text-xs font-medium text-dim transition hover:bg-danger/10 hover:text-danger"
            >
              Delete
            </button>
            <.icon name="hero-chevron-right" class="ml-auto h-4 w-4 text-faint" />
          </div>
        </div>
      </div>

      <div :if={@delete_confirm_id} class="fixed inset-0 z-50 overflow-y-auto">
        <div class="absolute inset-0 bg-black/70" phx-click="cancel_delete" aria-hidden="true"></div>
        <div class="relative flex min-h-full items-center justify-center p-4">
          <div
            role="dialog"
            aria-modal="true"
            class="w-full max-w-sm rounded-xl border border-line bg-card p-6 shadow-2xl"
          >
            <h3 class="font-display text-xl font-bold uppercase tracking-wide text-foreground">
              Delete Programme
            </h3>
            <p class="mt-2 text-sm text-dim">
              Are you sure you want to delete this programme? This action cannot be undone.
            </p>
            <div class="mt-6 flex items-center justify-end gap-3">
              <button
                type="button"
                phx-click="cancel_delete"
                class="rounded-md px-4 py-2 text-sm font-medium text-dim transition hover:text-foreground"
              >
                Cancel
              </button>
              <button
                type="button"
                phx-click="confirm_delete"
                class="rounded-md bg-danger px-4 py-2 text-sm font-semibold text-foreground transition hover:opacity-90"
              >
                Delete
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
