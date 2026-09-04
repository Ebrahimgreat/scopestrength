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

defmodule ScopestrengthWeb.Dashboard do
  alias Scopestrength.Notifications.Notification
  alias Scopestrength.Repo
  alias Scopestrength.Clients.Client
  use ScopestrengthWeb, :live_view
  alias Scopestrength.Trainers.Trainer
  alias Scopestrength.Trainers

  import Ecto.Query





  def handle_event("mark_notification_read", %{"id" => notification_id}, socket) do
    notification = Scopestrength.Notifications.get_notification!(notification_id)

    {:ok, _updated} = Scopestrength.Notifications.update_notification(notification, %{
      read_at: DateTime.utc_now()
    })

    activities =
      Enum.map(socket.assigns.activities, fn n ->
        if n.id == String.to_integer(notification_id) do
          %{n | read_at: DateTime.utc_now()}
        else
          n
        end
      end)

    {:noreply, assign(socket, activities: activities, notification_count: length(activities))}
  end

  def handle_event("mark_all_read", _params, socket) do
    trainer = Trainers.get_trainer_byUserId(socket.assigns.current_user.id)

    from(n in Notification,
      where: n.recipient_type == "trainer" and
             n.recipient_id == ^trainer.id and
             is_nil(n.read_at)
    )
    |> Repo.update_all(set: [read_at: DateTime.utc_now()])

    activities =
      Enum.map(socket.assigns.activities, fn n ->
        %{n | read_at: DateTime.utc_now()}
      end)

    {:noreply, assign(socket, activities: activities, notification_count: length(activities))}
  end
  def mount(_params, _session, socket) do



    user = socket.assigns.current_user



    case user.role do
      "trainer" ->
        trainer = Trainers.get_trainer_byUserId(user.id)
        programmes = Repo.all(from p in Scopestrength.Programmes.Programme, where: p.user_id == ^user.id)

        if connected?(socket) do
          Phoenix.PubSub.subscribe(
            Scopestrength.PubSub,
            "notifications:trainer:#{trainer.id}"
          )
        end
        notifications =
          Repo.all(
            from n in Notification,
              where: n.recipient_type == "trainer" and n.recipient_id == ^trainer.id and is_nil(n.read_at),
              order_by: [desc: n.inserted_at],
              limit: 10
          )
          client_ids= Enum.map(notifications, &(&1.actor_id))
          clients_by_id= Repo.all(from c in Client, where: c.user_id in ^client_ids)|>Repo.preload(:user)|>Map.new(&{&1.user_id,&1})

          notifications_with_client= Enum.map(notifications, fn n->
            case n.actor_type do
              "client" ->
                client = clients_by_id[n.actor_id]
                actor_name = if client && client.user, do: client.user.name, else: "Unknown Client"
                Map.put(n, :actor_name, actor_name)

              _ ->
                Map.put(n, :actor_name, "System")
            end
          end)

        data =
          Repo.get(Trainer, trainer.id)
          |> Repo.preload([clients: [:user]])

        {:ok,
         socket
         |> assign(:role, :trainer)
         |> assign(:name, user.name)
         |> assign(:message, "Trainer Dashboard")
         |> assign(:data, data)
         |> assign(:programmes, programmes)
         |> assign(:activities, notifications_with_client)
         |> assign(:notification_count, length(notifications_with_client))}


      "client" ->
        client = Repo.get_by(Client,%{user_id: user.id})

        {:ok,
         socket
         |> assign(:role, :client)
         |> assign(:name, user.name)
         |> assign(:message, "Client Dashboard")
         |> assign(:client, client)
         |> assign(:data, :"")
         |> assign(:activities, [])
         |> assign(:notification_count, 0)}

      _ ->
        {:halt, redirect(socket, to: "/login")}
    end
  end

  def handle_info({:notification, %Notification{} = notification}, socket) do
    activities = [with_actor_name(notification) | socket.assigns.activities] |> Enum.take(10)

    {:noreply,
     socket
     |> assign(:activities, activities)
     |> assign(:notification_count, length(activities))}
  end

  def handle_info(_, socket), do: {:noreply, socket}

  defp with_actor_name(%Notification{actor_type: "client", actor_id: actor_id} = notification) do
    name =
      case Repo.get_by(Client, user_id: actor_id) |> Repo.preload(:user) do
        %Client{user: %{name: name}} when is_binary(name) -> name
        _ -> "Unknown Client"
      end

    Map.put(notification, :actor_name, name)
  end

  defp with_actor_name(%Notification{} = notification) do
    Map.put(notification, :actor_name, "System")
  end

  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""

  <div class="w-full min-h-screen">
    <div class="w-full px-0 sm:px-2 lg:px-4 pt-10 pb-4">
      <h1 class="text-2xl uppercase sm:text-3xl lg:text-4xl font-semibold tracking-tight text-foreground">
        Trainer overview
      </h1>
      <p class="mt-2 text-dim text-sm sm:text-base lg:text-lg">Monitor client progress and track programmes.</p>
    </div>

    <div class="w-full px-0 sm:px-2 lg:px-4 py-8">


      <div class="mb-6 text-sm text-dim">
        <span class="font-medium text-foreground"><%= length(@data.clients) %></span> clients ·
        <span class="font-medium text-foreground"><%= length(@programmes) %></span> programmes ·

      </div>





      <div class="mb-8 bg-card border border-line rounded-2xl shadow-sm overflow-hidden">
        <div class="px-5 py-4 border-b border-line flex items-center justify-between">
          <div class="flex items-center gap-2">
            <.icon name="hero-bell-solid" class="h-5 w-5 text-primary" />
            <h2 class="text-base font-semibold text-foreground">Latest Activities</h2>
          </div>
          <div class="flex items-center gap-3">
            <span class="text-xs text-dim"><%= length(@activities) %> recent</span>
            <%= if Enum.any?(@activities, &is_nil(&1.read_at)) do %>
              <button
                phx-click="mark_all_read"
                class="text-xs text-primary hover:text-primary font-medium transition-colors"
              >
                Mark all read
              </button>
            <% end %>
            <.link
              navigate={~p"/trainer/notifications"}
              class="text-xs text-primary hover:text-primary font-medium transition-colors"
            >
              View all
            </.link>
          </div>
        </div>
        <%= if Enum.empty?(@activities) do %>
          <div class="px-5 py-6 text-sm text-dim">No notifications yet.</div>
        <% else %>
          <div class="divide-y divide-line">
            <%= for notification <- @activities do %>

              <div
                phx-click="mark_notification_read"
                phx-value-id={notification.id}
                class={"px-5 py-4 flex items-start justify-between gap-4 cursor-pointer transition-colors #{if is_nil(notification.read_at), do: "bg-primary/10 hover:bg-primary/10", else: "hover:bg-card"}"}
              >
                <div>
                  <p class="text-sm font-medium text-foreground">
                    <span class="text-primary"><%= notification.actor_name %></span>
                    <%= if notification.data["message"] do %>
                      <%= notification.data["message"] %>
                    <% else %>
                      <%= String.replace(notification.type, "_", " ") |> String.capitalize() %>
                    <% end %>
                  </p>
                  <p class="text-xs text-dim mt-1">
                    <%= notification_time(notification) %>
                  </p>
                </div>
                <%= if is_nil(notification.read_at) do %>
                  <span class="mt-1 h-2 w-2 rounded-full bg-primary flex-shrink-0"></span>
                <% end %>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>

      <div class="mb-8 bg-card border border-line rounded-2xl shadow-sm overflow-hidden">
        <div class="px-5 py-4 border-b border-line flex items-center justify-between">
          <h2 class="text-base font-semibold text-foreground">Programmes</h2>
          <span class="text-xs text-dim"><%= length(@programmes) %> total</span>
        </div>
        <%= if Enum.empty?(@programmes) do %>
          <div class="px-5 py-6 text-sm text-dim">No programmes yet.</div>
        <% else %>
          <div class="divide-y divide-line">
            <%= for programme <- @programmes do %>
              <.link navigate={~p"/trainer/programmes/#{programme.id}"} class="block px-5 py-4 hover:bg-card transition-colors">
                <p class="text-sm font-medium text-foreground"><%= programme.name %></p>
                <%= if programme.description do %>
                  <p class="text-xs text-dim mt-1"><%= programme.description %></p>
                <% end %>
              </.link>
            <% end %>
          </div>
        <% end %>
      </div>




    </div>
  </div>
  """
end

  defp notification_time(%Notification{inserted_at: %DateTime{} = inserted_at}) do
    Calendar.strftime(inserted_at, "%b %d, %Y at %I:%M %p")
  end

  defp notification_time(_), do: "Just now"

end
