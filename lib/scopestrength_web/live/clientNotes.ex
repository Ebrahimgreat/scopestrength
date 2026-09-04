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

defmodule ScopestrengthWeb.ClientNotes do
  import Ecto.Query
  alias Scopestrength.ClientNote
  alias Scopestrength.ClientNote.ClientNotes
  alias Scopestrength.Trainers
  alias Scopestrength.Clients
  alias Scopestrength.Repo
    use ScopestrengthWeb, :live_view

    def mount(params, _session, socket) do
      user = socket.assigns.current_user
      trainer = Trainers.get_trainer_byUserId(user.id)
      client_id = String.to_integer(params["id"])

      case Repo.get(Clients.Client, client_id) do
        nil ->
          {:ok,
           socket
           |> put_flash(:error, "Client Not found")
           |> push_navigate(to: "/trainer/clients")}

        client ->
          case client.trainer_id == trainer.id do
            true ->
              clientNote = ClientNotes.changeset(%ClientNotes{}, %{}) |> to_form()
              notes = Repo.all(from c in ClientNotes, where: c.client_id == ^client_id)
              {:ok, assign(socket, client_id: client_id, notes: notes, showModal: false, newForm: clientNote)}

            false ->
              {:ok,
               socket
               |> put_flash(:error, "Client Does not exist")
               |> push_navigate(to: "/trainer/clients")}
          end
      end
    end

    def handle_event("openModal", _params, socket) do
      showModal = !socket.assigns.showModal
      {:noreply, assign(socket, showModal: showModal)}


    end

    def handle_event("deleteNote", params, socket) do
      id = ScopestrengthWeb.Params.to_integer(params["id"])
      notes = ClientNote.get_client_notes!(id)
      case ClientNote.delete_client_notes(notes) do
        {:ok, _notes}->
          updatedNotes = Enum.reject(socket.assigns.notes, &(&1.id== id))
          {:noreply,assign(socket, notes: updatedNotes)}
          _ ->{:noreply,socket|>put_flash(:error, "An error has occured")}
      end

    end


    def handle_event("addNote", params, socket) do
      notes = params["client_notes"]["notes"]
      date =
        case Date.from_iso8601(params["client_notes"]["date"]) do
        {:ok, d} -> d
        _ -> nil
      end
      case ClientNote.create_client_notes(%{date: date, notes: notes, client_id: socket.assigns.client_id}) do
        {:ok, notes}->
          notes = socket.assigns.notes++[notes]
          {:noreply, socket|>assign(showModal: false, notes: notes)}

      _ ->{:noreply, socket|>put_flash(:error, "An error has occured")}
        end
    end
    def render(assigns) do
      ~H"""
      <div class="mx-auto max-w-5xl">
        <.back_link navigate={~p"/trainer/clients/#{@client_id}"}>Client</.back_link>
        <div class="flex flex-wrap items-end justify-between gap-4">
          <div>
            <p class="text-xs font-medium uppercase tracking-widest text-dim">Client</p>
            <h1 class="mt-1 font-display text-5xl font-bold uppercase tracking-wide text-foreground">
              Notes
            </h1>
            <p class="mt-2 max-w-xl text-sm text-dim">
              Observations and progress notes for this client.
            </p>
          </div>

          <.button type="button" phx-click="openModal" class="shrink-0">
            <span class="inline-flex items-center gap-2">
              <.icon name="hero-plus" class="h-4 w-4" /> Add note
            </span>
          </.button>
        </div>

        <div :if={@showModal} class="fixed inset-0 z-50 overflow-y-auto">
          <div class="absolute inset-0 bg-black/70" phx-click="openModal" aria-hidden="true"></div>
          <div class="relative flex min-h-full items-center justify-center p-4">
            <div
              role="dialog"
              aria-modal="true"
              class="w-full max-w-lg rounded-xl border border-line bg-card shadow-2xl"
            >
              <div class="border-b border-line px-6 py-4">
                <h2 class="font-display text-xl font-bold uppercase tracking-wide text-foreground">
                  Add note
                </h2>
              </div>

              <.form phx-submit="addNote" for={@newForm}>
                <div class="space-y-4 px-6 py-5">
                  <div>
                    <label class="mb-1 block text-xs uppercase tracking-widest text-dim">Date</label>
                    <input
                      type="date"
                      name={@newForm[:date].name}
                      value={@newForm[:date].value}
                      required
                      class="w-full rounded-md border-line bg-muted px-3 py-2.5 text-sm text-foreground focus:border-primary focus:ring-0"
                    />
                  </div>

                  <div>
                    <label class="mb-1 block text-xs uppercase tracking-widest text-dim">Note</label>
                    <textarea
                      name={@newForm[:notes].name}
                      rows="4"
                      placeholder="What happened in this session?"
                      class="w-full rounded-md border-line bg-muted px-3 py-2.5 text-sm text-foreground placeholder:text-faint focus:border-primary focus:ring-0"
                    ><%= Phoenix.HTML.Form.normalize_value("textarea", @newForm[:notes].value) %></textarea>
                  </div>
                </div>

                <div class="flex items-center justify-end gap-3 border-t border-line px-6 py-4">
                  <button
                    type="button"
                    phx-click="openModal"
                    class="rounded-md px-4 py-2 text-sm font-medium text-dim transition hover:text-foreground"
                  >
                    Cancel
                  </button>
                  <.button type="submit">Save note</.button>
                </div>
              </.form>
            </div>
          </div>
        </div>

        <div :if={@notes == []} class="mt-8 rounded-xl border border-dashed border-line px-6 py-16 text-center">
          <h3 class="font-display text-xl font-bold uppercase tracking-wide text-foreground">
            No notes yet
          </h3>
          <p class="mx-auto mt-2 max-w-sm text-sm text-dim">
            Start documenting this client's sessions by adding your first note.
          </p>
          <.button type="button" phx-click="openModal" class="mt-6">
            <span class="inline-flex items-center gap-2">
              <.icon name="hero-plus" class="h-4 w-4" /> Add your first note
            </span>
          </.button>
        </div>

        <div :if={@notes != []} class="mt-8 space-y-3">
          <div
            :for={note <- @notes}
            class="group rounded-xl border border-line bg-card p-5 transition hover:border-dim"
          >
            <div class="flex items-start justify-between gap-4">
              <div class="min-w-0 flex-1">
                <p class="num text-xs uppercase tracking-widest text-dim">
                  <%= note.date %>
                </p>
                <p class="mt-2 whitespace-pre-line text-sm leading-relaxed text-foreground">
                  <%= note.notes %>
                </p>
              </div>

              <.confirm
                id={"delete-note-#{note.id}"}
                title="Delete Note"
                message="Are you sure you want to delete this note? This action cannot be undone."
                confirm_label="Delete"
                on_confirm={JS.push("deleteNote", value: %{id: note.id})}
                aria-label="Delete note"
                class="shrink-0 rounded-md p-1.5 text-faint transition hover:bg-danger/10 hover:text-danger"
              >
                <.icon name="hero-trash" class="h-4 w-4" />
              </.confirm>
            </div>
          </div>
        </div>
      </div>
      """
    end
  end
