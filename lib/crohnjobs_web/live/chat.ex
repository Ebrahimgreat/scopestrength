defmodule CrohnjobsWeb.Chat do
  alias Crohnjobs.Chat.Message
  alias Crohnjobs.Clients.Client
  alias Crohnjobs.Repo
  import Ecto.Query
  use CrohnjobsWeb, :live_view

  @impl true
  def mount(params, _session, socket) do
    user = socket.assigns.current_user
    room_id = params["room"]
    messages = Repo.all(from m in Message, where: m.room_id == ^room_id, preload: [:user])
    topic = "chat:#{room_id}"

    back_path = if user.role == "trainer", do: "/trainer/chat", else: "/client/chat"
    other_user = fetch_other_user(user, room_id)

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
     |> assign(:other_user, other_user)
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
    <div class="min-h-screen bg-slate-50">
      <div class="max-w-5xl mx-auto px-4 py-6">
        <div class="flex items-center mb-4">
          <.link navigate={@back_path} class="text-sm text-slate-600 hover:text-slate-900 transition">
            &larr; Back
          </.link>
        </div>

        <div class="flex gap-4 items-start">
          <%!-- Chat column --%>
          <div class="flex-1 min-w-0">
            <div class="bg-white border border-slate-200 rounded-xl overflow-hidden shadow-sm">

              <%!-- Header --%>
              <div class="px-4 py-3 border-b border-slate-100 flex items-center gap-3">
                <%= if @other_user do %>
                  <%= if @other_user.profile_picture_url do %>
                    <img src={@other_user.profile_picture_url} class="w-9 h-9 rounded-full object-cover" />
                  <% else %>
                    <div class="w-9 h-9 rounded-full bg-slate-100 flex items-center justify-center text-sm font-semibold text-slate-600">
                      <%= String.first(@other_user.name || "?") |> String.upcase() %>
                    </div>
                  <% end %>
                  <div>
                    <p class="text-sm font-semibold text-slate-900"><%= @other_user.name %></p>
                    <p class="text-xs text-slate-400"><%= String.capitalize(@other_user.role) %></p>
                  </div>
                <% else %>
                  <p class="text-sm font-semibold text-slate-900">Chat</p>
                <% end %>
              </div>

              <%!-- Messages --%>
              <div class="h-[calc(100vh-230px)] overflow-y-auto p-4 bg-slate-50" id="messages-container" phx-hook="ScrollBottom">
                <%= if length(@messages) == 0 do %>
                  <div class="flex flex-col items-center justify-center h-full">
                    <div class="w-14 h-14 rounded-full bg-white border border-slate-200 flex items-center justify-center mb-3">
                      <svg class="w-6 h-6 text-slate-400" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path>
                      </svg>
                    </div>
                    <p class="text-sm font-medium text-slate-600">No messages yet</p>
                    <p class="text-xs text-slate-400 mt-0.5">Start the conversation</p>
                  </div>
                <% else %>
                  <div class="space-y-3">
                    <%= for msg <- @messages do %>
                      <%= if msg.user_id == @user.id do %>
                        <div class="flex flex-col items-end">
                          <div class="max-w-[70%] bg-slate-900 text-white px-4 py-2.5 rounded-tl-2xl rounded-tr-2xl rounded-bl-2xl rounded-br-sm">
                            <p class="text-sm leading-relaxed"><%= msg.text %></p>
                          </div>
                          <span class="text-xs text-slate-400 mt-1"><%= format_time(msg.inserted_at) %></span>
                        </div>
                      <% else %>
                        <div class="flex items-start gap-2">
                          <div class="w-8 h-8 rounded-full bg-white border border-slate-200 flex-shrink-0 flex items-center justify-center text-xs font-semibold text-slate-600 mt-0.5">
                            <%= sender_initial(msg) %>
                          </div>
                          <div class="max-w-[65%]">
                            <div class="bg-white border border-slate-200 px-4 py-2.5 rounded-tl-2xl rounded-tr-2xl rounded-bl-sm rounded-br-2xl">
                              <p class="text-sm text-slate-900 leading-relaxed"><%= msg.text %></p>
                            </div>
                            <span class="text-xs text-slate-400 mt-1 ml-1"><%= format_time(msg.inserted_at) %></span>
                          </div>
                        </div>
                      <% end %>
                    <% end %>
                  </div>
                <% end %>
              </div>

              <%!-- Input --%>
              <div class="p-3 bg-white border-t border-slate-100">
                <form phx-submit="send" class="flex items-center gap-2">
                  <input
                    type="text"
                    name="text"
                    value={@text}
                    autocomplete="off"
                    placeholder="Type a message…"
                    class="flex-1 bg-slate-100 rounded-full px-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-slate-300 focus:bg-white transition"
                  />
                  <button type="submit" class="w-9 h-9 bg-slate-900 rounded-full flex items-center justify-center hover:bg-slate-700 transition flex-shrink-0">
                    <svg class="w-4 h-4 text-white" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                      <line x1="22" y1="2" x2="11" y2="13"></line>
                      <polygon points="22 2 15 22 11 13 2 9 22 2"></polygon>
                    </svg>
                  </button>
                </form>
              </div>
            </div>
          </div>

          <%!-- Right sidebar --%>
          <%= if @other_user do %>
            <div class="w-72 flex-shrink-0 hidden md:block">
              <div class="bg-white border border-slate-200 rounded-xl shadow-sm p-5 sticky top-6">
                <div class="flex flex-col items-center mb-4">
                  <%= if @other_user.profile_picture_url do %>
                    <img src={@other_user.profile_picture_url} class="w-16 h-16 rounded-full object-cover mb-2" />
                  <% else %>
                    <div class="w-16 h-16 rounded-full bg-slate-100 flex items-center justify-center text-xl font-semibold text-slate-600 mb-2">
                      <%= String.first(@other_user.name || "?") |> String.upcase() %>
                    </div>
                  <% end %>
                  <h2 class="text-sm font-semibold text-slate-900"><%= @other_user.name %></h2>
                  <span class="text-xs text-slate-400"><%= String.capitalize(@other_user.role) %></span>
                </div>

                <div class="border-t border-slate-100 pt-3 space-y-2.5">
                  <%= if @other_user.role == "client" do %>
                    <%= if @other_user.age do %>
                      <div class="flex justify-between items-center">
                        <span class="text-xs text-slate-400">Age</span>
                        <span class="text-xs font-semibold text-slate-900"><%= @other_user.age %></span>
                      </div>
                    <% end %>
                    <%= if @other_user.height do %>
                      <div class="flex justify-between items-center">
                        <span class="text-xs text-slate-400">Height</span>
                        <span class="text-xs font-semibold text-slate-900"><%= format_number(@other_user.height) %> cm</span>
                      </div>
                    <% end %>
                    <%= if @other_user.sex do %>
                      <div class="flex justify-between items-center">
                        <span class="text-xs text-slate-400">Sex</span>
                        <span class="text-xs font-semibold text-slate-900"><%= String.capitalize(@other_user.sex) %></span>
                      </div>
                    <% end %>
                    <%= if @other_user.notes && @other_user.notes != "" do %>
                      <div class="pt-2.5 border-t border-slate-100">
                        <span class="text-xs text-slate-400">Notes</span>
                        <p class="text-xs text-slate-600 mt-1 leading-relaxed"><%= @other_user.notes %></p>
                      </div>
                    <% end %>
                  <% end %>

                  <%= if @other_user.role == "trainer" do %>
                    <%= if @other_user.specialization && @other_user.specialization != "" do %>
                      <div class="flex justify-between items-center">
                        <span class="text-xs text-slate-400">Specialization</span>
                        <span class="text-xs font-semibold text-slate-900"><%= @other_user.specialization %></span>
                      </div>
                    <% end %>
                    <%= if @other_user.bio && @other_user.bio != "" do %>
                      <div class="pt-2.5 border-t border-slate-100">
                        <span class="text-xs text-slate-400">About</span>
                        <p class="text-xs text-slate-600 mt-1 leading-relaxed"><%= @other_user.bio %></p>
                      </div>
                    <% end %>
                  <% end %>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp fetch_other_user(user, room_id) do
    case user.role do
      "trainer" ->
        case Integer.parse(room_id || "") do
          {client_id, ""} ->
            client = Repo.get(Client, client_id)

            if client do
              client = Repo.preload(client, :user)

              %{
                name: client.user && client.user.name,
                role: "client",
                profile_picture_url: client.profile_picture_url,
                age: client.age,
                height: client.height,
                sex: client.sex,
                notes: client.notes
              }
            end

          _ -> nil
        end

      _ ->
        client = Repo.get_by(Client, %{user_id: user.id})

        if client do
          client = Repo.preload(client, trainer: :user)

          case client.trainer do
            nil -> nil
            trainer ->
              %{
                name: trainer.user && trainer.user.name,
                role: "trainer",
                profile_picture_url: nil,
                bio: trainer.bio,
                specialization: trainer.specialization
              }
          end
        end
    end
  end

  defp format_time(nil), do: ""
  defp format_time(datetime), do: Calendar.strftime(datetime, "%H:%M")

  defp format_number(nil), do: "?"

  defp format_number(value) when is_float(value) do
    if value == Float.round(value, 0) do
      value |> round() |> Integer.to_string()
    else
      :erlang.float_to_binary(value, decimals: 1)
    end
  end

  defp format_number(value), do: to_string(value)

  defp sender_initial(%{user: nil}), do: "?"
  defp sender_initial(%{user: user}) do
    user.name
    |> then(&(&1 || "?"))
    |> String.first()
    |> String.upcase()
  end
end
