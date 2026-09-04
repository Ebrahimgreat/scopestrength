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

defmodule ScopestrengthWeb.Chat do
  alias Scopestrength.Chat
  alias Scopestrength.Chat.Message
  alias Scopestrength.Storage
  alias Scopestrength.Clients.Client
  alias Scopestrength.Notifications
  alias Scopestrength.Repo
  import Ecto.Query
  use ScopestrengthWeb, :live_view

  @impl true
  def mount(params, _session, socket) do
    user = socket.assigns.current_user
    room_id = params["room"]
    messages =
      Repo.all(from m in Message, where: m.room_id == ^room_id, preload: [:user, :attachments])
    topic = "chat:#{room_id}"

    back_path = if user.role == "trainer", do: "/trainer/chat", else: "/client/chat"
    other_user = fetch_other_user(user, room_id)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Scopestrength.PubSub, topic)
    end

    {:ok,
     socket
     |> assign(:room_id, room_id)
     |> assign(:messages, messages)
     |> assign(:user, user)
     |> assign(:topic, topic)
     |> assign(:back_path, back_path)
     |> assign(:other_user, other_user)
     |> assign(:text, "")
     |> assign(:input_version, 0)
     |> assign(:pending_attachments, %{})
     |> allow_attachments()}
  end

  defp allow_attachments(socket) do
    if Storage.direct_upload?() do
      allow_upload(socket, :attachment,
        accept: ~w(.jpg .jpeg .png .gif .webp .pdf .mp4 .mov),
        max_entries: 3,
        max_file_size: 100_000_000,
        external: &presign_attachment/2,
        progress: &handle_attachment_progress/3
      )
    else
      allow_upload(socket, :attachment,
        accept: ~w(.jpg .jpeg .png .gif .webp .pdf),
        max_entries: 3,
        max_file_size: 10_000_000
      )
    end
  end

  defp presign_attachment(entry, socket) do
    key = "chat/#{entry.uuid}.#{ext(entry)}"

    case Storage.presigned_put(key, entry.client_type) do
      {:ok, url} ->
        {:ok, %{uploader: "S3", key: key, url: url}, socket}

      {:error, reason} ->
        {:error, reason, socket}
    end
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :attachment, ref)}
  end

  @impl true
  def handle_event("send", %{"text" => text}, socket) do
    attachments =
      consume_uploaded_entries(socket, :attachment, fn meta, entry ->
        case meta do
          %{key: key} ->
            {:ok, attachment_attrs(key, entry)}

          %{path: path} ->
            case Storage.put(path, "chat", "#{entry.uuid}.#{ext(entry)}") do
              {:ok, key} -> {:ok, attachment_attrs(key, entry)}
              {:error, _reason} -> {:postpone, :error}
            end
        end
      end)
      |> Enum.reject(&(&1 == :error))

    in_flight =
      socket.assigns.uploads.attachment.entries
      |> Enum.reject(& &1.done?)
      |> Enum.map(fn entry ->
        {"chat/#{entry.uuid}.#{ext(entry)}",
         %{
           file_name: entry.client_name,
           content_type: entry.client_type,
           file_size: entry.client_size
         }}
      end)

    if String.trim(text) == "" and attachments == [] and in_flight == [] do
      {:noreply, socket}
    else
      attrs = %{
        text: text,
        user_id: socket.assigns.user.id,
        room_id: socket.assigns.room_id
      }

      {:noreply, create_and_broadcast(socket, attrs, attachments, in_flight)}
    end
  end

  defp create_and_broadcast(socket, attrs, attachments, in_flight) do
    result =
      Chat.create_message_with_mixed_attachments(
        attrs,
        attachments,
        Enum.map(in_flight, &elem(&1, 1))
      )

    case result do
      {:ok, {message, pending_rows}} ->
        message = Repo.preload(message, [:user, :attachments])

        Phoenix.PubSub.broadcast(
          Scopestrength.PubSub,
          socket.assigns.topic,
          {:new_message, message}
        )

        notify_recipient(socket, message)

        keys = Enum.map(in_flight, &elem(&1, 0))

        socket
        |> Phoenix.Component.update(:pending_attachments, fn pending ->
          Enum.zip(keys, Enum.map(pending_rows, & &1.id)) |> Enum.into(pending)
        end)
        |> assign(text: "")
        |> Phoenix.Component.update(:input_version, &(&1 + 1))

      {:error, _changeset} ->
        assign(socket, text: "")
    end
  end

  @impl true
  def handle_info({:new_message, message}, socket) do
    {:noreply, assign(socket, :messages, socket.assigns.messages ++ [message])}
  end

  @impl true
  def handle_info({:attachment_updated, attachment}, socket) do
    messages =
      Enum.map(socket.assigns.messages, fn message ->
        if message.id == attachment.message_id do
          attachments =
            Enum.map(message.attachments, fn a ->
              if a.id == attachment.id, do: attachment, else: a
            end)

          %{message | attachments: attachments}
        else
          message
        end
      end)

    {:noreply, assign(socket, :messages, messages)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-card">
      <div class="max-w-5xl mx-auto px-4 py-6">
        <div class="flex items-center mb-4">
          <.link navigate={@back_path} class="text-sm text-dim hover:text-foreground transition">
            &larr; Back
          </.link>
        </div>

        <div class="flex gap-4 items-start">
          <div class="flex-1 min-w-0">
            <div class="bg-card border border-line rounded-xl overflow-hidden shadow-sm">

              <div class="px-4 py-3 border-b border-line flex items-center gap-3">
                <%= if @other_user do %>
                  <%= if @other_user.profile_picture_url do %>
                    <img src={Storage.url(@other_user.profile_picture_url)} class="w-9 h-9 rounded-full object-cover" />
                  <% else %>
                    <div class="w-9 h-9 rounded-full bg-secondary flex items-center justify-center text-sm font-semibold text-dim">
                      <%= String.first(@other_user.name || "?") |> String.upcase() %>
                    </div>
                  <% end %>
                  <div>
                    <p class="text-sm font-semibold text-foreground"><%= @other_user.name %></p>
                    <p class="text-xs text-faint"><%= String.capitalize(@other_user.role) %></p>
                  </div>
                <% else %>
                  <p class="text-sm font-semibold text-foreground">Chat</p>
                <% end %>
              </div>

              <div class="h-[calc(100vh-230px)] overflow-y-auto p-4 bg-card" id="messages-container" phx-hook="ScrollBottom">
                <%= if length(@messages) == 0 do %>
                  <div class="flex flex-col items-center justify-center h-full">
                    <div class="w-14 h-14 rounded-full bg-card border border-line flex items-center justify-center mb-3">
                      <svg class="w-6 h-6 text-faint" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path>
                      </svg>
                    </div>
                    <p class="text-sm font-medium text-dim">No messages yet</p>
                    <p class="text-xs text-faint mt-0.5">Start the conversation</p>
                  </div>
                <% else %>
                  <div class="space-y-3">
                    <%= for {msg, day_label} <- with_day_breaks(@messages) do %>
                      <div :if={day_label} class="flex justify-center py-1">
                        <span class="rounded-full bg-secondary px-3 py-1 text-[11px] uppercase tracking-widest text-dim"><%= day_label %></span>
                      </div>
                      <%= if msg.user_id == @user.id do %>
                        <div class="flex flex-col items-end">
                          <div class="max-w-[70%] bg-card text-foreground px-4 py-2.5 rounded-tl-2xl rounded-tr-2xl rounded-bl-2xl rounded-br-sm">
                            <p :if={msg.text not in [nil, ""]} class="text-sm leading-relaxed"><%= msg.text %></p>
                            <.attachment_list attachments={msg.attachments} />
                          </div>
                          <span class="text-xs text-faint mt-1"><%= format_time(msg.inserted_at) %></span>
                        </div>
                      <% else %>
                        <div class="flex items-start gap-2">
                          <div class="w-8 h-8 rounded-full bg-card border border-line flex-shrink-0 flex items-center justify-center text-xs font-semibold text-dim mt-0.5">
                            <%= sender_initial(msg) %>
                          </div>
                          <div class="max-w-[65%]">
                            <div class="bg-card border border-line px-4 py-2.5 rounded-tl-2xl rounded-tr-2xl rounded-bl-sm rounded-br-2xl">
                              <p :if={msg.text not in [nil, ""]} class="text-sm text-foreground leading-relaxed"><%= msg.text %></p>
                              <.attachment_list attachments={msg.attachments} />
                            </div>
                            <span class="text-xs text-faint mt-1 ml-1"><%= format_time(msg.inserted_at) %></span>
                          </div>
                        </div>
                      <% end %>
                    <% end %>
                  </div>
                <% end %>
              </div>

              <div class="p-3 bg-card border-t border-line">
                <div :if={@uploads.attachment.entries != []} class="flex flex-wrap gap-2 mb-2">
                  <%= for entry <- @uploads.attachment.entries do %>
                    <div class="flex items-center gap-2 px-3 py-1.5 bg-secondary rounded-lg">
                      <span class="text-xs text-foreground truncate max-w-[160px]"><%= entry.client_name %></span>
                      <span class="text-xs text-faint"><%= entry.progress %>%</span>
                      <button
                        type="button"
                        phx-click="cancel_upload"
                        phx-value-ref={entry.ref}
                        class="text-faint hover:text-foreground transition"
                      >
                        &times;
                      </button>
                    </div>
                    <%= for err <- upload_errors(@uploads.attachment, entry) do %>
                      <p class="text-xs text-red-500 w-full"><%= upload_error_to_string(err) %></p>
                    <% end %>
                  <% end %>
                </div>
                <%= for err <- upload_errors(@uploads.attachment) do %>
                  <p class="text-xs text-red-500 mb-2"><%= upload_error_to_string(err) %></p>
                <% end %>

                <form phx-submit="send" phx-change="validate" class="flex items-center gap-2">
                  <.live_file_input upload={@uploads.attachment} class="sr-only" />
                  <label
                    for={@uploads.attachment.ref}
                    class="w-9 h-9 bg-secondary rounded-full flex items-center justify-center hover:opacity-80 transition flex-shrink-0 cursor-pointer"
                  >
                    <svg class="w-4 h-4 text-dim" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                      <path d="M21.44 11.05l-9.19 9.19a6 6 0 0 1-8.49-8.49l9.19-9.19a4 4 0 0 1 5.66 5.66l-9.2 9.19a2 2 0 0 1-2.83-2.83l8.49-8.48"></path>
                    </svg>
                  </label>
                  <input
                    id={"chat-input-#{@input_version}"}
                    phx-mounted={JS.focus()}
                    type="text"
                    name="text"
                    value={@text}
                    autocomplete="off"
                    placeholder="Type a message…"
                    class="flex-1 bg-secondary rounded-full px-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-slate-300 focus:bg-card transition"
                  />
                  <button
                    type="submit"
                    class="w-9 h-9 bg-card rounded-full flex items-center justify-center hover:bg-secondary transition flex-shrink-0"
                  >
                    <svg
                      class="w-4 h-4 text-foreground"
                      xmlns="http://www.w3.org/2000/svg"
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2.5"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                    >
                      <line x1="22" y1="2" x2="11" y2="13"></line>
                      <polygon points="22 2 15 22 11 13 2 9 22 2"></polygon>
                    </svg>
                  </button>
                </form>
              </div>
            </div>
          </div>

          <%= if @other_user do %>
            <div class="w-72 flex-shrink-0 hidden md:block">
              <div class="bg-card border border-line rounded-xl shadow-sm p-5 sticky top-6">
                <div class="flex flex-col items-center mb-4">
                  <%= if @other_user.profile_picture_url do %>
                    <img src={Storage.url(@other_user.profile_picture_url)} class="w-16 h-16 rounded-full object-cover mb-2" />
                  <% else %>
                    <div class="w-16 h-16 rounded-full bg-secondary flex items-center justify-center text-xl font-semibold text-dim mb-2">
                      <%= String.first(@other_user.name || "?") |> String.upcase() %>
                    </div>
                  <% end %>
                  <h2 class="text-sm font-semibold text-foreground"><%= @other_user.name %></h2>
                  <span class="text-xs text-faint"><%= String.capitalize(@other_user.role) %></span>
                </div>

                <div class="border-t border-line pt-3 space-y-2.5">
                  <%= if @other_user.role == "client" do %>
                    <%= if @other_user.age do %>
                      <div class="flex justify-between items-center">
                        <span class="text-xs text-faint">Age</span>
                        <span class="text-xs font-semibold text-foreground"><%= @other_user.age %></span>
                      </div>
                    <% end %>
                    <%= if @other_user.height do %>
                      <div class="flex justify-between items-center">
                        <span class="text-xs text-faint">Height</span>
                        <span class="text-xs font-semibold text-foreground"><%= format_number(@other_user.height) %> cm</span>
                      </div>
                    <% end %>
                    <%= if @other_user.sex do %>
                      <div class="flex justify-between items-center">
                        <span class="text-xs text-faint">Sex</span>
                        <span class="text-xs font-semibold text-foreground"><%= String.capitalize(@other_user.sex) %></span>
                      </div>
                    <% end %>
                    <%= if @other_user.notes && @other_user.notes != "" do %>
                      <div class="pt-2.5 border-t border-line">
                        <span class="text-xs text-faint">Notes</span>
                        <p class="text-xs text-dim mt-1 leading-relaxed"><%= @other_user.notes %></p>
                      </div>
                    <% end %>
                  <% end %>

                  <%= if @other_user.role == "trainer" do %>
                    <%= if @other_user.specialization && @other_user.specialization != "" do %>
                      <div class="flex justify-between items-center">
                        <span class="text-xs text-faint">Specialization</span>
                        <span class="text-xs font-semibold text-foreground"><%= @other_user.specialization %></span>
                      </div>
                    <% end %>
                    <%= if @other_user.bio && @other_user.bio != "" do %>
                      <div class="pt-2.5 border-t border-line">
                        <span class="text-xs text-faint">About</span>
                        <p class="text-xs text-dim mt-1 leading-relaxed"><%= @other_user.bio %></p>
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

  defp notify_recipient(socket, message) do
    sender = socket.assigns.user

    recipient =
      case sender.role do
        "trainer" ->
          case Integer.parse(socket.assigns.room_id || "") do
            {client_id, ""} -> {"client", client_id}
            _ -> nil
          end

        _ ->
          case Repo.get_by(Client, user_id: sender.id) do
            %Client{trainer_id: trainer_id} when not is_nil(trainer_id) ->
              {"trainer", trainer_id}

            _ ->
              nil
          end
      end

    case recipient do
      nil ->
        :ok

      {recipient_type, recipient_id} ->
        attrs = %{
          actor_id: sender.id,
          actor_type: sender.role,
          recipient_id: recipient_id,
          recipient_type: recipient_type,
          type: "message_received",
          data: %{
            room_id: socket.assigns.room_id,
            sender_name: sender.name,
            preview: preview(message.text)
          }
        }

        case Notifications.create_notification(attrs) do
          {:ok, notification} ->
            notification = Repo.get!(Notifications.Notification, notification.id)

            Phoenix.PubSub.broadcast(
              Scopestrength.PubSub,
              "notifications:#{recipient_type}:#{recipient_id}",
              {:notification, notification}
            )

          {:error, _changeset} ->
            :ok
        end
    end
  end

  defp preview(nil), do: "Sent an attachment"

  defp preview(text) do
    case String.trim(text) do
      "" -> "Sent an attachment"
      trimmed -> String.slice(trimmed, 0, 80)
    end
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

  attr :attachments, :list, required: true

  defp attachment_list(assigns) do
    ~H"""
    <div :if={@attachments != []} class="space-y-1.5 mt-1.5">
      <%= for att <- @attachments do %>
        <%= if image?(att) do %>
          <a href={Storage.url(att.file_url)} target="_blank" rel="noopener">
            <img src={Storage.url(att.file_url)} alt={att.file_name} class="max-w-full rounded-lg max-h-64 object-cover" />
          </a>
        <% else %>
          <a
            href={Storage.url(att.file_url)}
            target="_blank"
            rel="noopener"
            class="flex items-center gap-2 px-3 py-2 bg-secondary rounded-lg hover:opacity-80 transition"
          >
            <svg class="w-4 h-4 text-dim flex-shrink-0" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
              <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
              <polyline points="14 2 14 8 20 8"></polyline>
            </svg>
            <span class="text-xs text-foreground truncate"><%= att.file_name || "Attachment" %></span>
            <span class="text-xs text-faint flex-shrink-0"><%= format_size(att.file_size) %></span>
          </a>
        <% end %>
      <% end %>
    </div>
    """
  end

  defp ext(entry) do
    [ext | _] = MIME.extensions(entry.client_type)
    ext
  end

  defp handle_attachment_progress(:attachment, entry, socket) do
    if entry.done? do
      key = "chat/#{entry.uuid}.#{ext(entry)}"

      case Map.get(socket.assigns.pending_attachments, key) do
        nil ->
          {:noreply, socket}

        attachment_id ->
          consume_uploaded_entries(socket, :attachment, fn _meta, e ->
            if e.uuid == entry.uuid, do: {:ok, :consumed}, else: {:postpone, :skip}
          end)

          {:noreply, complete_attachment(socket, key, attachment_id)}
      end
    else
      {:noreply, socket}
    end
  end

  defp complete_attachment(socket, key, attachment_id) do
    case Chat.get_attachment(attachment_id) do
      nil ->
        socket

      attachment ->
        case Chat.mark_attachment_uploaded(attachment, key) do
          {:ok, updated} ->
            broadcast_attachment(socket, updated)

          {:error, _changeset} ->
            Chat.mark_attachment_failed(attachment)
            socket
        end

        Phoenix.Component.update(socket, :pending_attachments, &Map.delete(&1, key))
    end
  end

  defp broadcast_attachment(socket, attachment) do
    Phoenix.PubSub.broadcast(
      Scopestrength.PubSub,
      socket.assigns.topic,
      {:attachment_updated, attachment}
    )
  end

  defp attachment_attrs(key, entry) do
    %{
      file_url: key,
      file_name: entry.client_name,
      content_type: entry.client_type,
      file_size: entry.client_size
    }
  end

  defp upload_error_to_string(:too_large) do
    "File is too large (max #{if Storage.direct_upload?(), do: 100, else: 10} MB)"
  end
  defp upload_error_to_string(:too_many_files), do: "Too many files (max 3)"
  defp upload_error_to_string(:not_accepted), do: "That file type isn't supported"
  defp upload_error_to_string(_), do: "Upload failed"

  defp image?(%{content_type: "image/" <> _}), do: true
  defp image?(_), do: false

  defp format_size(nil), do: ""

  defp format_size(bytes) when bytes < 1_000_000 do
    "#{Float.round(bytes / 1_000, 1)} KB"
  end

  defp format_size(bytes), do: "#{Float.round(bytes / 1_000_000, 1)} MB"

  defp format_time(nil), do: ""
  defp format_time(datetime), do: Calendar.strftime(datetime, "%H:%M")

  defp with_day_breaks(messages) do
    {items, _last_day} =
      Enum.map_reduce(messages, nil, fn msg, previous_day ->
        day = NaiveDateTime.to_date(msg.inserted_at)
        label = if day == previous_day, do: nil, else: day_label(day)
        {{msg, label}, day}
      end)

    items
  end

  defp day_label(day) do
    today = Date.utc_today()

    cond do
      day == today -> "Today"
      day == Date.add(today, -1) -> "Yesterday"
      true -> Calendar.strftime(day, "%d %b %Y")
    end
  end

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
