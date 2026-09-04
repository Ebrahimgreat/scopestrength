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

defmodule ScopestrengthWeb.Notifications do
  use ScopestrengthWeb, :live_view
  alias Scopestrength.Notifications.Notification
  alias Scopestrength.Trainers
  alias Scopestrength.Repo
  alias Scopestrength.Notifications

  import Ecto.Query

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    trainer = Trainers.get_trainer_byUserId(user.id)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(
        Scopestrength.PubSub,
        "notifications:trainer:#{trainer.id}"
      )
    end

    {:ok, socket |> assign(trainer: trainer) |> load_notifications()}
  end

  @recent_limit 10

  defp load_notifications(socket) do
    trainer = socket.assigns.trainer

    notifications =
      Repo.all(
        from n in Notification,
          where: n.recipient_type == "trainer" and n.recipient_id == ^trainer.id,
          order_by: [desc: n.inserted_at],
          limit: @recent_limit
      )

    assign(socket, notifications: notifications)
  end

  def handle_event("mark_notification_read", %{"id" => notification_id}, socket) do
    notification = Notifications.get_notification!(notification_id)

    {:ok, _updated} = Notifications.update_notification(notification, %{
      read_at: DateTime.utc_now()
    })

    notifications =
      Enum.map(socket.assigns.notifications, fn n ->
        if n.id == String.to_integer(notification_id) do
          %{n | read_at: DateTime.utc_now()}
        else
          n
        end
      end)

    {:noreply, assign(socket, notifications: notifications)}
  end

  def handle_event("open", %{"id" => id}, socket) do
    {:noreply, socket} = handle_event("mark_notification_read", %{"id" => id}, socket)

    notification = Enum.find(socket.assigns.notifications, &(&1.id == String.to_integer(id)))

    case notification_destination(notification) do
      {:ok, path} -> {:noreply, push_navigate(socket, to: path)}
      {:gone, message} -> {:noreply, put_flash(socket, :error, message)}
      :none -> {:noreply, socket}
    end
  end

  def handle_event("mark_all_read", _params, socket) do
    trainer = socket.assigns.trainer

    from(n in Notification,
      where: n.recipient_type == "trainer" and
             n.recipient_id == ^trainer.id and
             is_nil(n.read_at)
    )
    |> Repo.update_all(set: [read_at: DateTime.utc_now()])

    notifications =
      Enum.map(socket.assigns.notifications, fn n ->
        %{n | read_at: DateTime.utc_now()}
      end)

    {:noreply, assign(socket, notifications: notifications)}
  end

  def handle_event("delete_notification", %{"id" => notification_id}, socket) do
    notification = Notifications.get_notification!(notification_id)
    {:ok, _} = Notifications.delete_notification(notification)

    notifications = Enum.reject(socket.assigns.notifications, &(&1.id == String.to_integer(notification_id)))

    {:noreply, socket |> assign(notifications: notifications) |> put_flash(:info, "Notification deleted")}
  end

  def handle_info({:notification, %Notification{} = notification}, socket) do
    notifications = Enum.take([notification | socket.assigns.notifications], @recent_limit)

    {:noreply, assign(socket, notifications: notifications)}
  end

  def handle_info(_, socket), do: {:noreply, socket}

  defp notification_destination(%Notification{type: "workout_created", data: data}) do
    with {:ok, client} <- fetch_client(data["client_id"]) do
      case data["workout_id"] do
        nil ->
          {:ok, ~p"/trainer/clients/#{client.id}/workouts"}

        workout_id ->
          case Repo.get_by(Scopestrength.Training.Workout, id: workout_id, client_id: client.id) do
            nil -> {:gone, "This workout no longer exists"}
            workout -> {:ok, ~p"/trainer/clients/#{client.id}/workouts/#{workout.id}"}
          end
      end
    end
  end

  defp notification_destination(%Notification{type: "progress_photo_uploaded", data: data}) do
    with {:ok, client} <- fetch_client(data["client_id"]) do
      {:ok, ~p"/trainer/clients/#{client.id}/progress-photos"}
    end
  end

  defp notification_destination(%Notification{type: "weight_logged", data: data}) do
    with {:ok, client} <- fetch_client(data["client_id"]) do
      {:ok, ~p"/trainer/clients/#{client.id}"}
    end
  end

  defp notification_destination(%Notification{type: type, data: data})
       when type in ["programme_assigned", "programme_updated", "programme_unenrolled"] do
    case data["programme_id"] do
      nil ->
        :none

      programme_id ->
        case Repo.get(Scopestrength.Programmes.Programme, programme_id) do
          nil -> {:gone, "This programme no longer exists"}
          programme -> {:ok, ~p"/trainer/programmes/#{programme.id}"}
        end
    end
  end

  defp notification_destination(_), do: :none

  defp fetch_client(nil), do: :none

  defp fetch_client(client_id) do
    case Repo.get(Scopestrength.Clients.Client, client_id) do
      nil -> {:gone, "This client no longer exists"}
      client -> {:ok, client}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-3xl">
      <.back_link navigate={~p"/trainer"}>Dashboard</.back_link>
      <div class="flex flex-wrap items-end justify-between gap-4">
        <div>
          <p class="text-xs font-medium uppercase tracking-widest text-dim">Activity</p>
          <h1 class="mt-1 font-display text-5xl font-bold uppercase tracking-wide text-foreground">
            Notifications
          </h1>
        </div>

        <button
          :if={Enum.any?(@notifications, &is_nil(&1.read_at))}
          phx-click="mark_all_read"
          class="shrink-0 rounded-md border border-line px-3 py-2 text-sm font-medium text-dim transition hover:border-primary hover:text-primary"
        >
          Mark all as read
        </button>
      </div>

      <div
        :if={@notifications == []}
        class="mt-8 rounded-xl border border-dashed border-line px-6 py-16 text-center"
      >
        <h3 class="font-display text-xl font-bold uppercase tracking-wide text-foreground">
          No notifications yet
        </h3>
        <p class="mx-auto mt-2 max-w-sm text-sm text-dim">
          When you receive notifications, they'll appear here.
        </p>
      </div>

      <div :if={@notifications != []} class="mt-8 overflow-hidden rounded-xl border border-line bg-card">
        <div
          :for={notification <- @notifications}
          role="link"
          tabindex="0"
          phx-click="open"
          phx-value-id={notification.id}
          class={[
            "flex items-start gap-4 border-b border-line/60 px-5 py-4 transition last:border-0 hover:bg-secondary/50",
            notification_link(notification) != "#" && "cursor-pointer",
            is_nil(notification.read_at) && "bg-primary/5"
          ]}
        >
          <div class={[
            "flex h-9 w-9 shrink-0 items-center justify-center rounded-full",
            is_nil(notification.read_at) && "bg-primary/15 text-primary",
            !is_nil(notification.read_at) && "bg-muted text-faint"
          ]}>
            <.icon name={notification_icon(notification)} class="h-4 w-4" />
          </div>

          <div class="min-w-0 flex-1">
            <p class={[
              "text-sm text-foreground",
              is_nil(notification.read_at) && "font-medium"
            ]}>
              <%= notification_text(notification) %>
            </p>
            <p class="mt-0.5 text-xs text-dim">
              <span :if={notification_actor(notification)}>
                <%= notification_actor(notification) %> ·
              </span>
              <span class="num"><%= notification_time(notification) %></span>
            </p>
          </div>

          <span
            :if={is_nil(notification.read_at)}
            class="mt-1.5 h-2 w-2 shrink-0 rounded-full bg-primary"
            aria-label="Unread"
          >
          </span>
        </div>
      </div>
    </div>
    """
  end

  defp notification_actor(%Notification{data: %{"client_name" => name}}) when is_binary(name),
    do: name

  defp notification_actor(_), do: nil

  defp notification_link(%Notification{type: "workout_created", data: data}) do
    case {data["client_id"], data["workout_id"]} do
      {nil, _} -> "#"
      {client_id, nil} -> ~p"/trainer/clients/#{client_id}/workouts"
      {client_id, workout_id} -> ~p"/trainer/clients/#{client_id}/workouts/#{workout_id}"
    end
  end

  defp notification_link(%Notification{type: "progress_photo_uploaded", data: data}) do
    case data["client_id"] do
      nil -> "#"
      client_id -> ~p"/trainer/clients/#{client_id}/progress-photos"
    end
  end

  defp notification_link(%Notification{type: "weight_logged", data: data}) do
    case data["client_id"] do
      nil -> "#"
      client_id -> ~p"/trainer/clients/#{client_id}"
    end
  end

  defp notification_link(%Notification{type: type, data: data})
       when type in ["programme_assigned", "programme_updated", "programme_unenrolled"] do
    case data["programme_id"] do
      nil -> "#"
      programme_id -> ~p"/trainer/programmes/#{programme_id}"
    end
  end

  defp notification_link(_), do: "#"

  defp notification_text(%Notification{data: %{"message" => message}}) when is_binary(message), do: message
  defp notification_text(%Notification{data: %{"title" => title}}) when is_binary(title), do: title
  defp notification_text(%Notification{type: "progress_photo_uploaded", data: data}) do
    case data["client_name"] do
      nil -> "A client uploaded a new progress photo"
      name -> "#{name} uploaded a progress photo"
    end
  end

  defp notification_text(%Notification{type: "workout_created", data: data}) do
    case data["client_name"] do
      nil -> "A client created a new workout"
      name -> "#{name} logged a workout"
    end
  end

  defp notification_text(%Notification{type: "weight_logged", data: data}) do
    case {data["client_name"], data["weight"]} do
      {nil, _} -> "A client logged their weight"
      {name, nil} -> "#{name} logged their weight"
      {name, weight} -> "#{name} logged their weight: #{weight}"
    end
  end
  defp notification_text(%Notification{type: "programme_assigned", data: data}) do
    case data["programme_name"] do
      nil -> "Programme assigned to client"
      name -> "Assigned #{name}"
    end
  end

  defp notification_text(%Notification{type: "programme_updated", data: data}) do
    case {data["previous_programme_name"], data["programme_name"]} do
      {nil, nil} -> "Client programme has been updated"
      {nil, name} -> "Changed programme to #{name}"
      {previous, nil} -> "Changed programme from #{previous}"
      {previous, name} -> "Changed programme from #{previous} to #{name}"
    end
  end

  defp notification_text(%Notification{type: "programme_unenrolled", data: data}) do
    case data["programme_name"] do
      nil -> "Client unenrolled from programme"
      name -> "Unenrolled client from #{name}"
    end
  end
  defp notification_text(%Notification{type: type}) when is_binary(type), do: String.replace(type, "_", " ") |> String.capitalize()
  defp notification_text(_), do: "New activity"

  defp notification_time(%Notification{inserted_at: %DateTime{} = inserted_at}) do
    now = DateTime.utc_now()
    diff = DateTime.diff(now, inserted_at, :second)

    cond do
      diff < 60 -> "Just now"
      diff < 3600 -> "#{div(diff, 60)} minutes ago"
      diff < 86400 -> "#{div(diff, 3600)} hours ago"
      diff < 604800 -> "#{div(diff, 86400)} days ago"
      true -> Calendar.strftime(inserted_at, "%b %d, %Y")
    end
  end

  defp notification_time(_), do: "Just now"

  defp notification_icon(%Notification{type: type}) do
    case type do
      "programme_assigned" -> "hero-document-plus"
      "programme_updated" -> "hero-arrow-path"
      "programme_unenrolled" -> "hero-x-circle"
      "workout_logged" -> "hero-clipboard-document-check"
      "workout_created" -> "hero-plus-circle"
      "progress_photo_uploaded" -> "hero-camera"
      _ -> "hero-bell"
    end
  end
end
