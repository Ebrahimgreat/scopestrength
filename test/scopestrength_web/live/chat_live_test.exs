defmodule ScopestrengthWeb.ChatLiveTest do
  use ScopestrengthWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Scopestrength.PeopleFixtures
  import Scopestrength.RecordsFixtures

  alias Scopestrength.Chat.Message
  alias Scopestrength.Repo

  setup :log_in_trainer

  test "sending a message stores it, clears the input and notifies the client", %{conn: conn, trainer: trainer, user: user} do
    client = client_fixture(%{trainer: trainer})
    {:ok, view, html} = live(conn, ~p"/chat/#{client.id}")
    assert html =~ ~s(id="chat-input-0")

    Phoenix.PubSub.subscribe(Scopestrength.PubSub, "chat:#{client.id}")
    html = render_submit(view, "send", %{"text" => "See you Monday"})
    assert html =~ ~s(id="chat-input-1")

    assert_receive {:new_message, _message}
    html = render(view)
    assert html =~ "See you Monday"
    assert html =~ "Today"

    [message] = Repo.all(Message)
    assert message.user_id == user.id
    assert message.room_id == to_string(client.id)

    [notification] = Repo.all(Scopestrength.Notifications.Notification)
    assert notification.type == "message_received"
    assert notification.recipient_type == "client"
    assert notification.recipient_id == client.id
  end

  test "blank messages are not sent", %{conn: conn, trainer: trainer} do
    client = client_fixture(%{trainer: trainer})
    {:ok, view, _html} = live(conn, ~p"/chat/#{client.id}")
    render_submit(view, "send", %{"text" => "   "})
    assert Repo.all(Message) == []
  end

  test "messages from different days get a date separator", %{conn: conn, trainer: trainer, user: user} do
    client = client_fixture(%{trainer: trainer})
    old = message_fixture(%{user_id: user.id, room_id: to_string(client.id), text: "old"})
    Repo.update_all(Message, set: [inserted_at: ~U[2026-01-15 10:00:00Z]])
    _new = message_fixture(%{user_id: user.id, room_id: to_string(client.id), text: "new"})
    _ = old

    {:ok, _view, html} = live(conn, ~p"/chat/#{client.id}")
    assert html =~ "15 Jan 2026"
    assert html =~ "Today"
  end
end
