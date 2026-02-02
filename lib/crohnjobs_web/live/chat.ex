defmodule CrohnjobsWeb.Chat do
  alias Crohnjobs.Chat.Message
  alias Crohnjobs.Clients.Client
  alias Crohnjobs.Repo
  alias Crohnjobs.Training
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

    maybe_send_progress_response(text, socket)

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
      <div class="max-w-3xl mx-auto px-4 py-6">
        <div class="flex items-center justify-between mb-4">
          <.link navigate={@back_path} class="text-sm text-slate-600 hover:text-slate-900 transition">
            &larr; Back
          </.link>
          <div class="text-sm text-slate-500"><%= @user.name %></div>
        </div>

        <div class="bg-white border border-slate-200 rounded-lg overflow-hidden">
          <div class="px-4 py-3 border-b border-slate-200">
            <h1 class="text-base font-semibold text-slate-900">Chat</h1>
          </div>

          <div class="h-[calc(100vh-220px)] overflow-y-auto p-4 bg-white" id="messages-container" phx-hook="ScrollBottom">
            <%= if length(@messages) == 0 do %>
              <div class="flex flex-col items-center justify-center h-full text-slate-400">
                <p class="text-sm">No messages yet.</p>
                <p class="text-sm">Start the conversation.</p>
              </div>
            <% else %>
              <div class="space-y-3">
                <%= for msg <- @messages do %>
                  <%= if msg.user_id == @user.id do %>
                    <div class="flex justify-end">
                      <div class="max-w-md">
                        <div class="text-xs text-slate-500 text-right mb-1">You</div>
                        <div class="bg-slate-900 text-white px-3 py-2 rounded-lg">
                          <%= msg.text %>
                        </div>
                      </div>
                    </div>
                  <% else %>
                    <div class="flex justify-start">
                      <div class="flex gap-2 max-w-md">
                        <div class="w-8 h-8 bg-slate-100 rounded-full flex-shrink-0 flex items-center justify-center text-xs font-semibold text-slate-600">
                          <%= sender_initial(msg) %>
                        </div>
                        <div>
                          <div class="text-xs text-slate-500 mb-1"><%= sender_name(msg) %></div>
                          <div class="bg-slate-50 border border-slate-200 px-3 py-2 rounded-lg text-slate-900">
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

          <div class="border-t border-slate-200 p-4 bg-white">
            <form phx-submit="send" class="flex gap-2">
              <input
                type="text"
                name="text"
                value={@text}
                autocomplete="off"
                placeholder="Type a message"
                class="flex-1 border border-slate-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-slate-300 focus:border-slate-300"
              />
              <button type="submit" class="bg-slate-900 text-white px-4 py-2 rounded-md hover:bg-slate-800 transition text-sm font-medium">
                Send
              </button>
            </form>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp maybe_send_progress_response(text, socket) do
    if progress_request?(text) do
      case build_progress_response(socket) do
        {:ok, response} -> send_bot_message(response, socket)
        {:error, message} -> send_bot_message(message, socket)
      end
    end
  end

  defp progress_request?(text) when is_binary(text) do
    text
    |> String.downcase()
    |> String.contains?("progress")
  end

  defp progress_request?(_), do: false

  defp build_progress_response(socket) do
    user = socket.assigns.user
    room_id = socket.assigns.room_id

    with {:ok, client} <- fetch_progress_client(user, room_id),
         {:ok, summary} <- Training.progress_summary(client.id) do
      {:ok, format_progress_text(client, summary)}
    else
      {:error, message} -> {:error, message}
      _ -> {:error, "I couldn't load progress for this client."}
    end
  end

  defp fetch_progress_client(user, room_id) do
    case user.role do
      "trainer" ->
        case Integer.parse(room_id || "") do
          {client_id, ""} ->
            case Repo.get(Client, client_id) |> Repo.preload(:user) do
              nil -> {:error, "I couldn't find that client."}
              client -> {:ok, client}
            end

          _ ->
            {:error, "I couldn't identify the client for this chat."}
        end

      _ ->
        case Repo.get_by(Client, %{user_id: user.id}) |> Repo.preload(:user) do
          nil -> {:error, "I couldn't find your client profile."}
          client -> {:ok, client}
        end
    end
  end

  defp format_progress_text(client, summary) do
    name =
      case client.user do
        nil -> "This client"
        user -> user.name || "This client"
      end

    if summary.total_workouts == 0 do
      "No workouts logged yet for #{name}."
    else
      last_workout =
        case summary.last_workout_at do
          nil -> "unknown"
          datetime -> format_date(datetime)
        end

      base =
        "#{name} progress: #{summary.total_workouts} workouts logged, #{summary.total_sets} total sets. Last workout: #{last_workout}."

      pr_text =
        case summary.pr do
          nil ->
            "No PRs recorded yet."

          pr ->
            reps = format_number(pr.reps)
            weight = format_number(pr.weight)
            date_text = format_date(pr.date)
            "Top lift: #{pr.exercise_name} #{weight} kg x #{reps} (#{date_text})."
        end

      base <> " " <> pr_text
    end
  end

  defp format_date(%DateTime{} = datetime) do
    Calendar.strftime(datetime, "%d %b %Y")
  end

  defp format_date(%NaiveDateTime{} = datetime) do
    Calendar.strftime(datetime, "%d %b %Y")
  end

  defp format_date(_), do: "unknown"

  defp format_number(nil), do: "?"

  defp format_number(value) when is_float(value) do
    if value == Float.round(value, 0) do
      value |> round() |> Integer.to_string()
    else
      :erlang.float_to_binary(value, decimals: 1)
    end
  end

  defp format_number(value), do: to_string(value)

  defp send_bot_message(text, socket) when is_binary(text) do
    attrs = %{
      text: text,
      user_id: nil,
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
  end

  defp sender_name(%{user: nil}), do: "CoachBot"
  defp sender_name(%{user: user}), do: user.name || "CoachBot"

  defp sender_initial(%{user: nil}), do: "AI"
  defp sender_initial(%{user: user}) do
    user.name
    |> then(&(&1 || "?"))
    |> String.first()
    |> String.upcase()
  end
end
