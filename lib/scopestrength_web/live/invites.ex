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

defmodule ScopestrengthWeb.Invites do
  use ScopestrengthWeb, :live_view
  alias Scopestrength.Trainers
  alias Scopestrength.Invites

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    trainer = Trainers.get_trainer_byUserId(user.id)
    invites = Invites.list_invites_for_trainer(trainer.id)

    {:ok, assign(socket,
      trainer_id: trainer.id,
      invites: invites,
      email: "",
      show_form: false,
      new_invite: nil
    )}
  end

  def handle_event("toggle_form", _params, socket) do
    {:noreply, assign(socket, show_form: !socket.assigns.show_form, email: "", new_invite: nil)}
  end

  def handle_event("update_email", %{"email" => email}, socket) do
    {:noreply, assign(socket, email: email)}
  end

  def handle_event("create_invite", %{"email" => email}, socket) do
    case Invites.create_invite(socket.assigns.trainer_id, email) do
      {:ok, invite} ->
        invites = Invites.list_invites_for_trainer(socket.assigns.trainer_id)
        {:noreply, socket
          |> assign(invites: invites, new_invite: invite, email: "")
          |> put_flash(:info, "Invite created successfully!")}

      {:error, changeset} ->
        error_msg = changeset.errors |> Enum.map(fn {k, {msg, _}} -> "#{k} #{msg}" end) |> Enum.join(", ")
        {:noreply, socket |> put_flash(:error, "Error: #{error_msg}")}
    end
  end

  def handle_event("delete_invite", %{"id" => id}, socket) do
    case Invites.delete_invite(ScopestrengthWeb.Params.to_integer(id), socket.assigns.trainer_id) do
      {:ok, _} ->
        invites = Invites.list_invites_for_trainer(socket.assigns.trainer_id)
        {:noreply, socket
          |> assign(invites: invites)
          |> put_flash(:info, "Invite deleted")}

      {:error, _} ->
        {:noreply, socket |> put_flash(:error, "Could not delete invite")}
    end
  end

  def render(assigns) do
    assigns =
      assign(assigns,
        pending_count: Enum.count(assigns.invites, &(!&1.used)),
        used_count: Enum.count(assigns.invites, & &1.used)
      )

    ~H"""
    <div class="mx-auto max-w-5xl">
      <div class="flex flex-wrap items-end justify-between gap-4">
        <div>
          <p class="text-xs font-medium uppercase tracking-widest text-dim">Trainer</p>
          <h1 class="mt-1 font-display text-4xl font-bold uppercase tracking-wide text-foreground">
            Client Invites
          </h1>
          <p class="mt-2 max-w-xl text-sm text-dim">
            Generate a code, share it with your client, and they can link to your account after signing up.
          </p>
        </div>

        <.button phx-click="toggle_form" class="shrink-0">
          <span class="inline-flex items-center gap-2">
            <.icon name={if @show_form, do: "hero-x-mark", else: "hero-plus"} class="h-4 w-4" />
            {if @show_form, do: "Cancel", else: "New Invite"}
          </span>
        </.button>
      </div>

      <div :if={@show_form} class="mt-8 rounded-xl border border-line bg-card p-6">
        <h2 class="font-display text-xl font-bold uppercase tracking-wide text-foreground">
          Create New Invite
        </h2>
        <form phx-submit="create_invite" class="mt-4 space-y-4">
          <div>
            <label for="invite-email" class="mb-2 block text-sm font-medium text-foreground">
              Client Email
            </label>
            <input
              type="email"
              id="invite-email"
              name="email"
              value={@email}
              phx-change="update_email"
              placeholder="client@example.com"
              required
              class="w-full rounded-md border-line bg-muted px-4 py-3 text-foreground placeholder:text-faint focus:border-primary focus:ring-0"
            />
            <p class="mt-2 text-sm text-dim">
              Only this email address can use the generated invite code.
            </p>
          </div>
          <.button type="submit">Generate Invite Code</.button>
        </form>
      </div>

      <div
        :if={@new_invite}
        class="mt-8 rounded-xl border border-primary/40 bg-primary/5 p-6"
      >
        <div class="flex items-start gap-4">
          <div class="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-primary">
            <.icon name="hero-check" class="h-5 w-5 text-primary-foreground" />
          </div>
          <div class="min-w-0 flex-1">
            <h3 class="font-display text-lg font-bold uppercase tracking-wide text-primary">
              Invite Created
            </h3>
            <p class="mt-1 text-sm text-dim">
              Share this code with <span class="text-foreground">{@new_invite.email}</span>.
            </p>

            <div class="mt-4 flex flex-wrap items-center gap-3 rounded-lg border border-line bg-background p-4">
              <span class="num flex-1 text-2xl font-bold tracking-[0.2em] text-foreground">
                {@new_invite.code}
              </span>
              <button
                type="button"
                id={"copy-new-#{@new_invite.id}"}
                phx-hook="Copy"
                data-clipboard-text={@new_invite.code}
                class="inline-flex items-center gap-2 rounded-md border border-line px-3 py-2 text-sm font-medium text-dim transition hover:border-primary hover:text-primary"
              >
                <.icon name="hero-clipboard-document" class="h-4 w-4" />
                <span data-copy-label>Copy</span>
              </button>
            </div>

            <p class="mt-3 text-sm text-dim">
              The client will enter this code after registering to link with you.
            </p>
          </div>
        </div>
      </div>

      <div class="mt-8 grid grid-cols-2 gap-4">
        <.stat
          label="Pending Invites"
          value={@pending_count}
          unit={unit(@pending_count, "code")}
          note={@invites != [] && "#{percent(@pending_count, length(@invites))}% of all invites"}
          note_class="text-warning"
        />
        <.stat
          label="Accepted Invites"
          value={@used_count}
          unit={unit(@used_count, "client")}
          note={@invites != [] && "#{percent(@used_count, length(@invites))}% of all invites"}
          note_class="text-primary"
        />
      </div>

      <div :if={@invites == []} class="mt-8 rounded-xl border border-dashed border-line px-6 py-16 text-center">
        <div class="mx-auto flex h-14 w-14 items-center justify-center rounded-full bg-secondary">
          <.icon name="hero-envelope" class="h-7 w-7 text-faint" />
        </div>
        <h3 class="mt-4 font-display text-xl font-bold uppercase tracking-wide text-foreground">
          No invites yet
        </h3>
        <p class="mx-auto mt-2 max-w-sm text-sm text-dim">
          Create invite codes to allow clients to connect with you.
        </p>
      </div>

      <div :if={@invites != []} class="mt-8 overflow-hidden rounded-xl border border-line bg-card">
        <div class="flex items-center justify-between border-b border-line px-5 py-4">
          <h2 class="text-sm font-semibold text-foreground">All Invites</h2>
          <span class="num text-xs text-dim">{length(@invites)} total</span>
        </div>

        <div class="hidden md:block">
          <table class="min-w-full">
            <thead>
              <tr class="border-b border-line text-left">
                <th class="px-5 py-3 text-xs font-medium uppercase tracking-widest text-dim">Email</th>
                <th class="px-5 py-3 text-xs font-medium uppercase tracking-widest text-dim">Code</th>
                <th class="px-5 py-3 text-xs font-medium uppercase tracking-widest text-dim">Status</th>
                <th class="px-5 py-3 text-xs font-medium uppercase tracking-widest text-dim">Created</th>
                <th class="px-5 py-3 text-right text-xs font-medium uppercase tracking-widest text-dim">
                  <span class="sr-only">Actions</span>
                </th>
              </tr>
            </thead>
            <tbody>
              <tr
                :for={invite <- @invites}
                class="border-b border-line/60 transition last:border-0 hover:bg-secondary/50"
              >
                <td class="px-5 py-4 text-sm text-foreground">{invite.email}</td>
                <td class="px-5 py-4">
                  <button
                    type="button"
                    id={"copy-row-#{invite.id}"}
                    phx-hook="Copy"
                    data-clipboard-text={invite.code}
                    class="num group inline-flex items-center gap-2 rounded-md bg-muted px-2.5 py-1 text-sm font-semibold text-foreground transition hover:text-primary"
                  >
                    {invite.code}
                    <.icon
                      name="hero-clipboard-document"
                      class="h-3.5 w-3.5 text-faint transition group-hover:text-primary"
                    />
                    <span data-copy-label class="sr-only">Copy</span>
                  </button>
                </td>
                <td class="px-5 py-4"><.status used={invite.used} /></td>
                <td class="num px-5 py-4 text-sm text-dim">
                  {Calendar.strftime(invite.inserted_at, "%b %d, %Y")}
                </td>
                <td class="px-5 py-4 text-right">
                  <.confirm
                    :if={!invite.used}
                    id={"delete-invite-#{invite.id}"}
                    title="Delete Invite"
                    message="Are you sure you want to delete this invite?"
                    confirm_label="Delete"
                    on_confirm={JS.push("delete_invite", value: %{id: invite.id})}
                    class="rounded-md px-2 py-1 text-sm font-medium text-dim transition hover:bg-danger/10 hover:text-danger"
                  >
                    Delete
                  </.confirm>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="divide-y divide-line md:hidden">
          <div :for={invite <- @invites} class="space-y-3 p-5">
            <div class="flex items-start justify-between gap-3">
              <span class="min-w-0 flex-1 truncate text-sm text-foreground">{invite.email}</span>
              <.status used={invite.used} />
            </div>
            <div class="flex items-center gap-3">
              <button
                type="button"
                id={"copy-card-#{invite.id}"}
                phx-hook="Copy"
                data-clipboard-text={invite.code}
                class="num inline-flex items-center gap-2 rounded-md bg-muted px-2.5 py-1 text-sm font-semibold text-foreground"
              >
                {invite.code}
                <.icon name="hero-clipboard-document" class="h-3.5 w-3.5 text-faint" />
                <span data-copy-label class="sr-only">Copy</span>
              </button>
              <span class="num text-xs text-dim">
                {Calendar.strftime(invite.inserted_at, "%b %d, %Y")}
              </span>
            </div>
            <.confirm
              :if={!invite.used}
              id={"delete-invite-card-#{invite.id}"}
              title="Delete Invite"
              message="Are you sure you want to delete this invite?"
              confirm_label="Delete"
              on_confirm={JS.push("delete_invite", value: %{id: invite.id})}
              class="text-sm font-medium text-dim transition hover:text-danger"
            >
              Delete
            </.confirm>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :value, :integer, required: true
  attr :unit, :string, default: nil
  attr :note, :any, default: nil
  attr :note_class, :string, default: "text-dim"

  defp stat(assigns) do
    ~H"""
    <div class="rounded-xl border border-line bg-card p-5">
      <p class="text-xs font-medium uppercase tracking-widest text-dim">{@label}</p>
      <p class="mt-3 flex items-baseline gap-1.5">
        <span class="num text-4xl font-medium leading-none text-foreground">{@value}</span>
        <span :if={@unit} class="num text-sm text-dim">{@unit}</span>
      </p>
      <p :if={@note} class={"num mt-3 text-xs #{@note_class}"}>{@note}</p>
    </div>
    """
  end

  defp unit(1, singular), do: singular
  defp unit(_, singular), do: singular <> "s"

  defp percent(_part, 0), do: 0
  defp percent(part, total), do: round(part / total * 100)

  attr :used, :boolean, required: true

  defp status(assigns) do
    ~H"""
    <span class={[
      "inline-flex shrink-0 items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-medium",
      @used && "bg-primary/10 text-primary",
      !@used && "bg-warning/10 text-warning"
    ]}>
      <span class={["h-1.5 w-1.5 rounded-full", @used && "bg-primary", !@used && "bg-warning"]} />
      {if @used, do: "Used", else: "Pending"}
    </span>
    """
  end
end
