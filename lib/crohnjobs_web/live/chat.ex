defmodule CrohnjobsWeb.Chat do
alias Crohnjobs.Chat.Message
alias Crohnjobs.Repo
import Ecto.Query
  use CrohnjobsWeb, :live_view

  @impl true
  def mount(params, _session, socket) do
    user = socket.assigns.current_user
    room_id = params["room"]
    messages = Repo.all(from m in Message, where: m.room_id == ^room_id, preload: [:user])
    topic = "chat:#{room_id}"


    if connected?(socket) do
      Phoenix.PubSub.subscribe(Crohnjobs.PubSub, topic)
    end

    {:ok,
     socket
     |> assign(:room_id, room_id)
     |> assign(:messages, messages)
     |> assign(:user, user)
     |> assign(:topic, topic)
     |> assign(:text, "")}
  end

  @impl true
  def handle_event("send", %{"text" => text}, socket) do
    attrs = %{
      text: text,
      user_id: socket.assigns.user.id,
      room_id: socket.assigns.room_id
    }

    case Crohnjobs.Chat.create_message(attrs) do
      {:ok, message} ->
        message = Repo.preload(message, :user)
        Phoenix.PubSub.broadcast(
          Crohnjobs.PubSub,
          socket.assigns.topic,
          {:new_message, message}
        )
      {:error, _changeset} ->
        :ok
    end

    {:noreply, assign(socket, text: "")}
  end

  @impl true
  def handle_info({:new_message, message}, socket) do
    {:noreply, assign(socket, :messages, socket.assigns.messages ++ [message])}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto p-4">
      <h1 class="text-2xl font-bold mb-4">Chat</h1>

      <div class="border border-gray-300 rounded-lg h-96 overflow-y-auto p-4 bg-gray-50 mb-4">
        <%= if length(@messages) == 0 do %>
          <div class="flex items-center justify-center h-full text-gray-400">
            No messages yet. Start the conversation!
          </div>
        <% else %>
          <div class="space-y-3">
            <%= for msg <- @messages do %>
              <%= if msg.user_id == @user.id do %>
                <div class="flex justify-end">
                  <div class="max-w-xs">
                    <div class="text-xs text-gray-500 text-right mb-1">You</div>
                    <div class="bg-blue-500 text-white px-4 py-2 rounded-lg rounded-br-none">
                      <%= msg.text %>
                    </div>
                  </div>
                </div>
              <% else %>
                <div class="flex justify-start">
                  <div class="max-w-xs">
                    <div class="text-xs text-gray-500 mb-1"><%= msg.user.name %></div>
                    <div class="bg-white border border-gray-200 px-4 py-2 rounded-lg rounded-bl-none shadow-sm">
                      <%= msg.text %>
                    </div>
                  </div>
                </div>
              <% end %>
            <% end %>
          </div>
        <% end %>
      </div>

      <form phx-submit="send" class="flex gap-2">
        <input
          type="text"
          name="text"
          value={@text}
          autocomplete="off"
          placeholder="Type a message..."
          class="flex-1 border border-gray-300 rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
        <button type="submit" class="bg-blue-500 text-white px-6 py-2 rounded-lg hover:bg-blue-600 transition">
          Send
        </button>
      </form>
    </div>
    """
  end
end
