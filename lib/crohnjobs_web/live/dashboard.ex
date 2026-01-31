defmodule CrohnjobsWeb.Dashboard do
  alias Crohnjobs.Notifications.Notification
  alias CrohnjobsWeb.Clients
  alias Crohnjobs.Repo
  alias Crohnjobs.Clients.Client
  use CrohnjobsWeb, :live_view
  alias Crohnjobs.Clients
  alias Crohnjobs.Trainers.Trainer
  alias Crohnjobs.Trainers

  import Ecto.Query



  def handle_event("updateStatus", params, socket) do


   newClient = Clients.get_client!(params["id"])
   status = newClient.active
   Clients.update_client(newClient,%{active: !status})

  {:noreply, assign(socket, clients: Clients.list_clients)}

  end

  def handle_event("mark_notification_read", %{"id" => notification_id}, socket) do
    notification = Crohnjobs.Notifications.get_notification!(notification_id)

    {:ok, _updated} = Crohnjobs.Notifications.update_notification(notification, %{
      read_at: DateTime.utc_now()
    })

    # Update the activities list
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

    # Update all unread notifications for this trainer
    from(n in Notification,
      where: n.recipient_type == "trainer" and
             n.recipient_id == ^trainer.id and
             is_nil(n.read_at)
    )
    |> Repo.update_all(set: [read_at: DateTime.utc_now()])

    # Update local state
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
        programmes = Repo.all(from p in Crohnjobs.Programmes.Programme, where: p.trainer_id == ^trainer.id)

        if connected?(socket) do
          Phoenix.PubSub.subscribe(
            Crohnjobs.PubSub,
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
          #SO actor id is basically the user_id
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
          IO.inspect(notifications_with_client)






        data =
          Repo.get(Trainer, trainer.id)
          |> Repo.preload([:programmes, clients: [:user]])


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
    activities = [notification | socket.assigns.activities] |> Enum.take(10)

    {:noreply,
     socket
     |> assign(:activities, activities)
     |> assign(:notification_count, length(activities))}
  end

  def handle_info(_, socket), do: {:noreply, socket}

  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""

  <div class="w-full min-h-screen">
    <!-- Header -->
    <div class="w-full px-6 lg:px-10 pt-10 pb-4">
      <h1 class="text-3xl lg:text-4xl font-semibold tracking-tight text-slate-900">
        Welcome back, <span class="text-emerald-700"><%= @name %></span>.
      </h1>
      <p class="mt-2 text-slate-600 text-base lg:text-lg">Here’s your trainer overview.</p>
    </div>

    <!-- Main Content -->
    <div class="w-full px-6 lg:px-10 py-8">


      <div class="mb-6 text-sm text-slate-600">
        <span class="font-medium text-slate-800"><%= length(@data.clients) %></span> clients ·
        <span class="font-medium text-slate-800"><%= length(@data.programmes) %></span> programmes
      </div>

      <div class="mb-8 bg-white border border-slate-200 rounded-2xl shadow-sm overflow-hidden">
        <div class="px-5 py-4 border-b border-slate-100 flex items-center justify-between">
          <div class="flex items-center gap-2">
            <.icon name="hero-bell-solid" class="h-5 w-5 text-emerald-600" />
            <h2 class="text-base font-semibold text-slate-900">Latest Activities</h2>
          </div>
          <div class="flex items-center gap-3">
            <span class="text-xs text-slate-500"><%= length(@activities) %> recent</span>
            <%= if Enum.any?(@activities, &is_nil(&1.read_at)) do %>
              <button
                phx-click="mark_all_read"
                class="text-xs text-emerald-600 hover:text-emerald-700 font-medium transition-colors"
              >
                Mark all read
              </button>
            <% end %>
            <.link
              navigate={~p"/trainer/notifications"}
              class="text-xs text-emerald-600 hover:text-emerald-700 font-medium transition-colors"
            >
              View all
            </.link>
          </div>
        </div>
        <%= if Enum.empty?(@activities) do %>
          <div class="px-5 py-6 text-sm text-slate-500">No notifications yet.</div>
        <% else %>
          <div class="divide-y divide-slate-100">
            <%= for notification <- @activities do %>

              <div
                phx-click="mark_notification_read"
                phx-value-id={notification.id}
                class={"px-5 py-4 flex items-start justify-between gap-4 cursor-pointer transition-colors #{if is_nil(notification.read_at), do: "bg-emerald-50 hover:bg-emerald-100", else: "hover:bg-slate-50"}"}
              >
                <div>
                  <p class="text-sm font-medium text-slate-900">
                    <span class="text-emerald-600"><%= notification.actor_name %></span>
                    <%= if notification.data["message"] do %>
                      <%= notification.data["message"] %>
                    <% else %>
                      <%= String.replace(notification.type, "_", " ") |> String.capitalize() %>
                    <% end %>
                  </p>
                  <p class="text-xs text-slate-500 mt-1">
                    <%= notification_time(notification) %>
                  </p>
                </div>
                <%= if is_nil(notification.read_at) do %>
                  <span class="mt-1 h-2 w-2 rounded-full bg-emerald-500 flex-shrink-0"></span>
                <% end %>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>

      <div class="mb-8 bg-white border border-slate-200 rounded-2xl shadow-sm overflow-hidden">
        <div class="px-5 py-4 border-b border-slate-100 flex items-center justify-between">
          <h2 class="text-base font-semibold text-slate-900">Programmes</h2>
          <span class="text-xs text-slate-500"><%= length(@data.programmes) %> total</span>
        </div>
        <%= if Enum.empty?(@data.programmes) do %>
          <div class="px-5 py-6 text-sm text-slate-500">No programmes yet.</div>
        <% else %>
          <div class="divide-y divide-slate-100">
            <%= for programme <- @data.programmes do %>
              <.link navigate={~p"/trainer/programmes/#{programme.id}"} class="block px-5 py-4 hover:bg-slate-50 transition-colors">
                <p class="text-sm font-medium text-slate-900"><%= programme.name %></p>
                <%= if programme.description do %>
                  <p class="text-xs text-slate-500 mt-1"><%= programme.description %></p>
                <% end %>
              </.link>
            <% end %>
          </div>
        <% end %>
      </div>


      <div class="py-8 text-sm text-slate-500">
        Your programmes and clients are managed from the left navigation.
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
