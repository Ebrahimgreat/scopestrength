defmodule ScopestrengthWeb.Client.Notifications do
  use ScopestrengthWeb, :live_view
  alias Scopestrength.Notifications.Notification
  alias Scopestrength.Clients.Client
  alias Scopestrength.Repo
  alias Scopestrength.Notifications

  import Ecto.Query

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    client = Repo.get_by(Client, %{user_id: user.id})

    if connected?(socket) do
      Phoenix.PubSub.subscribe(
        Scopestrength.PubSub,
        "notifications:client:#{client.id}"
      )
    end

    notifications =
      Repo.all(
        from n in Notification,
          where: n.recipient_type == "client" and n.recipient_id == ^client.id,
          order_by: [desc: n.inserted_at]
      )

    {:ok, assign(socket, client: client, notifications: notifications)}
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
    client = socket.assigns.client

    # Update all unread notifications for this client
    from(n in Notification,
      where: n.recipient_type == "client" and
             n.recipient_id == ^client.id and
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



  def handle_info({:notification, %Notification{} = notification}, socket) do
    notifications = [notification | socket.assigns.notifications]

    {:noreply, assign(socket, notifications: notifications)}
  end

  def handle_info(_, socket), do: {:noreply, socket}

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-3xl">
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
          phx-click="mark_notification_read"
          phx-value-id={notification.id}
          class={[
            "flex cursor-pointer items-start gap-4 border-b border-line/60 px-5 py-4 transition last:border-0 hover:bg-secondary/50",
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
            <p class="num mt-0.5 text-xs text-dim"><%= notification_time(notification) %></p>
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
      _ -> "hero-bell"
    end
  end
end
