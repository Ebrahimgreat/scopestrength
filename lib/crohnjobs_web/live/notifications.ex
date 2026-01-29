defmodule CrohnjobsWeb.Notifications do
  use CrohnjobsWeb, :live_view
  alias Crohnjobs.Notifications.Notification
  alias Crohnjobs.Trainers
  alias Crohnjobs.Repo
  alias Crohnjobs.Notifications

  import Ecto.Query

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    trainer = Trainers.get_trainer_byUserId(user.id)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(
        Crohnjobs.PubSub,
        "notifications:trainer:#{trainer.id}"
      )
    end

    notifications =
      Repo.all(
        from n in Notification,
          where: n.recipient_type == "trainer" and n.recipient_id == ^trainer.id,
          order_by: [desc: n.inserted_at]
      )

    {:ok, assign(socket, trainer: trainer, notifications: notifications)}
  end

  def handle_event("mark_notification_read", %{"id" => notification_id}, socket) do
    notification = Notifications.get_notification!(notification_id)

    {:ok, _updated} = Notifications.update_notification(notification, %{
      read_at: DateTime.utc_now()
    })

    # Update the notifications list
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

  def handle_event("mark_all_read", _params, socket) do
    trainer = socket.assigns.trainer

    # Update all unread notifications for this trainer
    from(n in Notification,
      where: n.recipient_type == "trainer" and
             n.recipient_id == ^trainer.id and
             is_nil(n.read_at)
    )
    |> Repo.update_all(set: [read_at: DateTime.utc_now()])

    # Update local state
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
    notifications = [notification | socket.assigns.notifications]

    {:noreply, assign(socket, notifications: notifications)}
  end

  def handle_info(_, socket), do: {:noreply, socket}

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-white py-8">
      <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <!-- Header -->
        <div class="mb-8">
          <div class="bg-white rounded-xl shadow-lg border-2 border-slate-200 p-6">
            <div class="flex items-center justify-between">
              <div class="flex items-center space-x-4">
                <div class="w-16 h-16 bg-emerald-600 rounded-full flex items-center justify-center shadow-lg">
                  <.icon name="hero-bell-solid" class="w-8 h-8 text-white" />
                </div>
                <div>
                  <h1 class="text-3xl font-bold text-slate-900">Notifications</h1>
                  <p class="text-slate-600 mt-1">Stay updated with your training activities</p>
                </div>
              </div>
              <.link
                navigate={~p"/trainer"}
                class="inline-flex items-center px-4 py-2 bg-slate-600 hover:bg-slate-700 text-white font-semibold rounded-lg shadow-md transition-all duration-200"
              >
                <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
                </svg>
                Back to Dashboard
              </.link>
            </div>
          </div>
        </div>

        <!-- Actions Bar -->
        <%= if Enum.any?(@notifications, &is_nil(&1.read_at)) do %>
          <div class="mb-4 flex justify-end">
            <button
              phx-click="mark_all_read"
              class="inline-flex items-center px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white font-semibold rounded-lg shadow-md transition-all duration-200"
            >
              <.icon name="hero-check-circle" class="w-5 h-5 mr-2" />
              Mark All as Read
            </button>
          </div>
        <% end %>

        <!-- Notifications List -->
        <div class="bg-white rounded-xl shadow-lg border-2 border-slate-200 overflow-hidden">
          <%= if Enum.empty?(@notifications) do %>
            <div class="p-12 text-center">
              <div class="w-20 h-20 bg-slate-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <.icon name="hero-bell" class="w-10 h-10 text-slate-400" />
              </div>
              <h3 class="text-xl font-bold text-slate-900 mb-2">No notifications yet</h3>
              <p class="text-slate-600">When you receive notifications, they'll appear here</p>
            </div>
          <% else %>
            <div class="divide-y divide-slate-200">
              <%= for notification <- @notifications do %>
                <div class={"group relative transition-colors #{if is_nil(notification.read_at), do: "bg-emerald-50 hover:bg-emerald-100", else: "hover:bg-slate-50"}"}>
                  <div
                    phx-click="mark_notification_read"
                    phx-value-id={notification.id}
                    class="px-6 py-5 cursor-pointer"
                  >
                    <div class="flex items-start justify-between gap-4">
                      <div class="flex-1">
                        <div class="flex items-start gap-3">
                          <div class={"w-10 h-10 rounded-full flex items-center justify-center flex-shrink-0 #{if is_nil(notification.read_at), do: "bg-emerald-600", else: "bg-slate-400"}"}>
                            <.icon name={notification_icon(notification)} class="w-5 h-5 text-white" />
                          </div>
                          <div class="flex-1 min-w-0">
                            <p class={"text-sm font-medium text-slate-900 #{if is_nil(notification.read_at), do: "font-bold"}"}>
                              <%= notification_text(notification) %>
                            </p>
                            <p class="text-xs text-slate-500 mt-1">
                              <%= notification_time(notification) %>
                            </p>
                          </div>
                        </div>
                      </div>
                      <div class="flex items-center gap-2">
                        <%= if is_nil(notification.read_at) do %>
                          <span class="h-2.5 w-2.5 rounded-full bg-emerald-500 flex-shrink-0"></span>
                        <% end %>

                      </div>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp notification_text(%Notification{data: %{"message" => message}}) when is_binary(message), do: message
  defp notification_text(%Notification{data: %{"title" => title}}) when is_binary(title), do: title
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
      _ -> "hero-bell"
    end
  end
end
