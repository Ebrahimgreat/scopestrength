defmodule ScopestrengthWeb.UnreadNotifications do
  @moduledoc """
  LiveView on_mount hook that keeps `@unread_count` current for the sidebar bell.

  Subscribing inside a single LiveView only works while that page is open, so a
  badge rendered by the layout needs the subscription hoisted to the
  live_session. Attaching here means every page in the session listens, and the
  count survives navigation.

  Usage:
      on_mount ScopestrengthWeb.UnreadNotifications
  """

  import Phoenix.LiveView
  import Phoenix.Component
  import Ecto.Query

  alias Scopestrength.Repo
  alias Scopestrength.Notifications.Notification

  def on_mount(:default, _params, _session, socket) do
    case recipient(socket.assigns[:current_user]) do
      nil ->
        {:cont, assign(socket, unread_count: 0)}

      {type, id} ->
        if connected?(socket) do
          Phoenix.PubSub.subscribe(Scopestrength.PubSub, "notifications:#{type}:#{id}")
        end

        {:cont,
         socket
         |> assign(unread_count: unread_count(type, id))
         |> attach_hook(:unread_notifications, :handle_info, &refresh/2)}
    end
  end

  # Any notification broadcast on the subscribed topic re-reads the count rather
  # than incrementing, so marking things read elsewhere stays consistent.
  # {:cont, socket} lets the page's own handle_info clauses still see the
  # message — a hook must return a 2-tuple; the 3-tuple form is :handle_event only.
  defp refresh({:notification, _}, socket) do
    case recipient(socket.assigns[:current_user]) do
      nil -> {:cont, socket}
      {type, id} -> {:cont, assign(socket, unread_count: unread_count(type, id))}
    end
  end

  # Catch-all is required: the hook receives every message the LiveView gets.
  defp refresh(_message, socket), do: {:cont, socket}

  # Topics are keyed by the client/trainer record id, not the user id.
  defp recipient(%{id: user_id, role: "client"}) do
    case Repo.get_by(Scopestrength.Clients.Client, user_id: user_id) do
      nil -> nil
      client -> {"client", client.id}
    end
  end

  # Scopestrength.Accounts.Trainer is an empty stub schema; the real one with
  # user_id lives under Trainers, which is what the Trainers context uses too.
  defp recipient(%{id: user_id, role: "trainer"}) do
    case Repo.get_by(Scopestrength.Trainers.Trainer, user_id: user_id) do
      nil -> nil
      trainer -> {"trainer", trainer.id}
    end
  end

  defp recipient(_), do: nil

  defp unread_count(type, id) do
    Repo.aggregate(
      from(n in Notification,
        where: n.recipient_type == ^type and n.recipient_id == ^id and is_nil(n.read_at)
      ),
      :count,
      :id
    )
  end
end
