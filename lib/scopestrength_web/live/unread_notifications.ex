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

  defp refresh({:notification, notification}, socket) do
    case recipient(socket.assigns[:current_user]) do
      nil ->
        {:cont, socket}

      {type, id} ->
        {:cont,
         socket
         |> assign(unread_count: unread_count(type, id))
         |> flash_for(notification)}
    end
  end

  defp refresh(_message, socket), do: {:cont, socket}

  defp flash_for(socket, %{type: "message_received", data: data}) do
    if socket.assigns[:room_id] == field(data, "room_id") do
      socket
    else
      put_flash(socket, :notification, "#{field(data, "sender_name")}: #{field(data, "preview")}")
    end
  end

  defp flash_for(socket, %{type: type, data: data}) do
    put_flash(socket, :notification, describe(type, data))
  end

  defp flash_for(socket, _notification), do: socket

  defp describe("workout_created", data), do: "#{field(data, "client_name")} logged a workout"
  defp describe("weight_logged", data), do: "#{field(data, "client_name")} logged a weight entry"

  defp describe("progress_photo_uploaded", data),
    do: "#{field(data, "client_name")} added a progress photo"

  defp describe(_type, _data), do: "You have a new notification"

  defp field(data, key) when is_map(data) do
    Map.get(data, key) || Map.get(data, String.to_existing_atom(key))
  rescue
    ArgumentError -> nil
  end

  defp field(_data, _key), do: nil

  defp recipient(%{id: user_id, role: "client"}) do
    case Repo.get_by(Scopestrength.Clients.Client, user_id: user_id) do
      nil -> nil
      client -> {"client", client.id}
    end
  end

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
