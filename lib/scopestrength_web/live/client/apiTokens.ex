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

defmodule ScopestrengthWeb.Client.ApiTokens do
  @moduledoc """
  Issue and revoke API tokens for your own training data.

  A new token's plaintext is held in assigns only until the next action: it is
  never stored, so this page is the one and only chance to copy it.
  """
  use ScopestrengthWeb, :live_view

  alias Scopestrength.ApiTokens
  alias Scopestrength.ApiTokens.ApiToken
  alias Scopestrength.Clients

  @impl true
  def mount(_params, _session, socket) do
    client = Clients.get_client_byUserId(socket.assigns.current_user.id)

    {:ok,
     socket
     |> assign(client: client, new_token: nil, error: nil)
     |> assign(form_name: "", form_scope: "read", form_expiry: "90")
     |> load_tokens()}
  end

  @impl true
  def handle_event("create", params, socket) do
    case String.trim(params["name"] || "") do
      "" ->
        {:noreply, assign(socket, error: "Give the token a name so you can recognise it later.")}

      name ->
        attrs = %{
          name: name,
          scope: params["scope"] || "read",
          expires_in_days: expiry_days(params["expiry"]),
          client_id: socket.assigns.client.id,
          user_id: socket.assigns.current_user.id
        }

        case ApiTokens.create_token(attrs) do
          {:ok, plaintext, _token} ->
            {:noreply,
             socket
             |> assign(new_token: plaintext, error: nil, form_name: "")
             |> load_tokens()}

          {:error, changeset} ->
            {:noreply, assign(socket, error: changeset_message(changeset))}
        end
    end
  end

  def handle_event("update_form", params, socket) do
    {:noreply,
     assign(socket,
       form_name: params["name"] || socket.assigns.form_name,
       form_scope: params["scope"] || socket.assigns.form_scope,
       form_expiry: params["expiry"] || socket.assigns.form_expiry
     )}
  end

  def handle_event("revoke", %{"id" => id}, socket) do
    case ApiTokens.revoke_token(socket.assigns.client.id, String.to_integer(id)) do
      {:ok, _} -> {:noreply, socket |> assign(new_token: nil, error: nil) |> load_tokens()}
      {:error, :not_found} -> {:noreply, assign(socket, error: "That token no longer exists.")}
      {:error, _} -> {:noreply, assign(socket, error: "Could not revoke that token.")}
    end
  end

  def handle_event("dismiss_token", _params, socket) do
    {:noreply, assign(socket, new_token: nil)}
  end

  defp load_tokens(socket) do
    assign(socket, tokens: ApiTokens.list_for_client(socket.assigns.client.id))
  end

  defp expiry_days("never"), do: nil
  defp expiry_days(value) when is_binary(value), do: value
  defp expiry_days(_), do: 90

  defp changeset_message(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {msg, _} -> msg end)
    |> Enum.map_join("; ", fn {field, msgs} -> "#{field} #{Enum.join(msgs, ", ")}" end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-3xl">
      <p class="num text-xs font-medium uppercase tracking-widest text-dim">Settings</p>
      <h1 class="mt-1 font-display text-5xl font-bold uppercase tracking-wide text-foreground">
        API tokens
      </h1>
      <p class="mt-2 max-w-xl text-sm text-dim">
        A token lets an application read your training data through the API. Give
        each application its own, so you can withdraw one without affecting the rest.
      </p>

      <div
        :if={@new_token}
        class="mt-8 rounded-xl border border-primary bg-card p-5"
      >
        <h2 class="text-sm font-semibold text-foreground">Copy this now</h2>
        <p class="mt-1 text-sm text-dim">
          This is the only time the token is shown. If you lose it, revoke it and make another.
        </p>
        <p class="num mt-4 break-all rounded-md bg-muted px-3 py-2.5 text-sm text-primary">
          {@new_token}
        </p>
        <button
          type="button"
          phx-click="dismiss_token"
          class="num mt-4 text-xs uppercase tracking-widest text-dim transition hover:text-foreground"
        >
          Done
        </button>
      </div>

      <div class="mt-8 rounded-xl border border-line bg-card p-5">
        <h2 class="text-sm font-semibold text-foreground">New token</h2>

        <form phx-submit="create" phx-change="update_form" class="mt-4 flex flex-wrap items-end gap-3">
          <label class="flex min-w-0 flex-1 flex-col gap-1">
            <span class="num text-[10px] uppercase tracking-widest text-faint">Name</span>
            <input
              type="text"
              name="name"
              value={@form_name}
              placeholder="my_app"
              autocomplete="off"
              class="min-w-0 rounded-md border-line bg-muted px-3 py-2.5 text-sm text-foreground placeholder:text-faint focus:border-primary focus:ring-0"
            />
          </label>

          <label class="flex flex-col gap-1">
            <span class="num text-[10px] uppercase tracking-widest text-faint">Access</span>
            <select
              name="scope"
              class="rounded-md border-line bg-muted px-3 py-2.5 text-sm text-foreground focus:border-primary focus:ring-0"
            >
              <option value="read" selected={@form_scope == "read"}>Read only</option>
              <option value="read_write" selected={@form_scope == "read_write"}>Read and write</option>
            </select>
          </label>

          <label class="flex flex-col gap-1">
            <span class="num text-[10px] uppercase tracking-widest text-faint">Expires</span>
            <select
              name="expiry"
              class="rounded-md border-line bg-muted px-3 py-2.5 text-sm text-foreground focus:border-primary focus:ring-0"
            >
              <option value="30" selected={@form_expiry == "30"}>30 days</option>
              <option value="90" selected={@form_expiry == "90"}>90 days</option>
              <option value="365" selected={@form_expiry == "365"}>1 year</option>
              <option value="never" selected={@form_expiry == "never"}>Never</option>
            </select>
          </label>

          <.button type="submit">Create</.button>
        </form>

        <p :if={@error} class="mt-3 text-sm text-danger">{@error}</p>
      </div>

      <div class="mt-8 overflow-hidden rounded-xl border border-line bg-card">
        <div class="flex items-baseline justify-between gap-3 border-b border-line px-5 py-4">
          <h2 class="font-semibold text-foreground">Your tokens</h2>
          <span class="num text-xs text-dim">{length(@tokens)}</span>
        </div>

        <div :if={@tokens == []} class="px-5 py-12 text-center text-sm text-dim">
          No tokens yet.
        </div>

        <div
          :for={token <- @tokens}
          class="flex flex-wrap items-center justify-between gap-3 border-b border-line/60 px-5 py-4 last:border-0"
        >
          <div class="min-w-0">
            <div class="flex items-center gap-2">
              <span class="text-sm font-medium text-foreground">{token.name}</span>
              <span class={status_class(token)}>{ApiToken.status(token)}</span>
              <span :if={token.scope == "read_write"} class="num text-[10px] uppercase tracking-widest text-warning">
                read/write
              </span>
            </div>
            <p class="num mt-1 text-xs text-dim">
              sst_{token.prefix}… · created {format_date(token.inserted_at)} · {last_used(token)}{expiry(token)}
            </p>
          </div>

          <button
            :if={is_nil(token.revoked_at)}
            type="button"
            phx-click="revoke"
            phx-value-id={token.id}
            data-confirm={"Revoke #{token.name}? Anything using it will stop working immediately."}
            class="num shrink-0 text-xs uppercase tracking-widest text-dim transition hover:text-danger"
          >
            Revoke
          </button>
        </div>
      </div>
    </div>
    """
  end

  defp status_class(token) do
    base = "num rounded-full px-2 py-0.5 text-[10px] uppercase tracking-widest "

    case ApiToken.status(token) do
      "active" -> base <> "bg-secondary text-primary"
      "revoked" -> base <> "bg-secondary text-danger"
      _ -> base <> "bg-secondary text-dim"
    end
  end

  defp last_used(%{last_used_at: nil}), do: "never used"
  defp last_used(%{last_used_at: at}), do: "last used #{format_date(at)}"

  defp expiry(%{revoked_at: at}) when not is_nil(at), do: " · revoked #{format_date(at)}"
  defp expiry(%{expires_at: nil}), do: " · no expiry"
  defp expiry(%{expires_at: at}), do: " · expires #{format_date(at)}"

  defp format_date(nil), do: "—"
  defp format_date(%DateTime{} = dt), do: Calendar.strftime(dt, "%d %b %Y")
  defp format_date(%NaiveDateTime{} = dt), do: Calendar.strftime(dt, "%d %b %Y")
end
