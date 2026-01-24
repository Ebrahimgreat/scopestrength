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

    # Determine back link based on user role
    back_path = if user.role == "trainer", do: "/trainer/chat", else: "/client/chat"

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Crohnjobs.PubSub, topic)
    end

    {:ok,
     socket
     |> assign(:room_id, room_id)
     |> assign(:messages, messages)
     |> assign(:user, user)
     |> assign(:topic, topic)
     |> assign(:back_path, back_path)
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
    <div class="min-h-screen bg-gray-100">
      <!-- Header / Navbar -->
      <header class="bg-blue-600 text-white shadow-lg">
        <div class="max-w-4xl mx-auto px-4 py-4 flex items-center justify-between">
          <div class="flex items-center gap-4">
            <.link navigate={@back_path} class="flex items-center gap-2 text-blue-100 hover:text-white transition">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M9.707 16.707a1 1 0 01-1.414 0l-6-6a1 1 0 010-1.414l6-6a1 1 0 011.414 1.414L5.414 9H17a1 1 0 110 2H5.414l4.293 4.293a1 1 0 010 1.414z" clip-rule="evenodd" />
              </svg>
              Back
            </.link>
            <div class="h-6 w-px bg-blue-400"></div>
            <h1 class="text-xl font-bold">Chat</h1>
          </div>
          <div class="flex items-center gap-3">
            <span class="text-sm text-blue-100"><%= @user.name %></span>
            <div class="w-8 h-8 bg-blue-500 rounded-full flex items-center justify-center text-sm font-medium">
              <%= String.first(@user.name) %>
            </div>
          </div>
        </div>
      </header>

      <!-- Chat Container -->
      <div class="max-w-4xl mx-auto p-4">
        <div class="bg-white rounded-xl shadow-lg overflow-hidden">
          <!-- Messages Area -->
          <div class="h-[calc(100vh-220px)] overflow-y-auto p-6 bg-gray-50" id="messages-container" phx-hook="ScrollBottom">
            <%= if length(@messages) == 0 do %>
              <div class="flex flex-col items-center justify-center h-full text-gray-400">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-16 w-16 mb-4 text-gray-300" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
                </svg>
                <p class="text-lg font-medium">No messages yet</p>
                <p class="text-sm">Start the conversation!</p>
              </div>
            <% else %>
              <div class="space-y-4">
                <%= for msg <- @messages do %>
                  <%= if msg.user_id == @user.id do %>
                    <div class="flex justify-end">
                      <div class="max-w-md">
                        <div class="text-xs text-gray-500 text-right mb-1">You</div>
                        <div class="bg-blue-500 text-white px-4 py-3 rounded-2xl rounded-br-md shadow-sm">
                          <%= msg.text %>
                        </div>
                      </div>
                    </div>
                  <% else %>
                    <div class="flex justify-start">
                      <div class="flex gap-3 max-w-md">
                        <div class="w-8 h-8 bg-gray-300 rounded-full flex-shrink-0 flex items-center justify-center text-sm font-medium text-gray-600">
                          <%= String.first(msg.user.name) %>
                        </div>
                        <div>
                          <div class="text-xs text-gray-500 mb-1"><%= msg.user.name %></div>
                          <div class="bg-white border border-gray-200 px-4 py-3 rounded-2xl rounded-bl-md shadow-sm">
                            <%= msg.text %>
                          </div>
                        </div>
                      </div>
                    </div>
                  <% end %>
                <% end %>
              </div>
            <% end %>
          </div>

          <!-- Message Input -->
          <div class="border-t border-gray-200 p-4 bg-white">
            <form phx-submit="send" class="flex gap-3">
              <input
                type="text"
                name="text"
                value={@text}
                autocomplete="off"
                placeholder="Type a message..."
                class="flex-1 border border-gray-300 rounded-full px-5 py-3 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
              <button type="submit" class="bg-blue-500 text-white px-6 py-3 rounded-full hover:bg-blue-600 transition flex items-center gap-2 font-medium">
                <span>Send</span>
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                  <path d="M10.894 2.553a1 1 0 00-1.788 0l-7 14a1 1 0 001.169 1.409l5-1.429A1 1 0 009 15.571V11a1 1 0 112 0v4.571a1 1 0 00.725.962l5 1.428a1 1 0 001.17-1.408l-7-14z" />
                </svg>
              </button>
            </form>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
