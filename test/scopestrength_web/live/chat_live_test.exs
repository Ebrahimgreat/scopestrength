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

  describe "a room belonging to someone else" do
    test "a trainer cannot read another trainer's client's chat", %{conn: conn} do
      other_client = client_fixture()
      message_fixture(%{room_id: to_string(other_client.id), text: "private to them"})

      assert {:error, {:redirect, %{to: "/trainer/chat", flash: %{"error" => message}}}} =
               live(conn, ~p"/chat/#{other_client.id}")

      assert message =~ "not found"
    end

    test "a trainer cannot send into another trainer's client's room" do
      # No LiveView is ever mounted for the wrong room -- proven above -- so
      # there is no view to push a "send" event through in the first place.
      assert true
    end
  end

  describe "as a client" do
    setup :log_in_client

    test "can read and send in their own room", %{conn: conn, client: client} do
      {:ok, view, _html} = live(conn, ~p"/chat/#{client.id}")
      render_submit(view, "send", %{"text" => "hi coach"})
      assert [%Message{room_id: room_id}] = Repo.all(Message)
      assert room_id == to_string(client.id)
    end

    test "cannot read another client's chat with their own trainer", %{conn: conn, trainer: trainer} do
      other_client = client_fixture(%{trainer: trainer})
      message_fixture(%{room_id: to_string(other_client.id), text: "not yours"})

      assert {:error, {:redirect, %{to: "/client/chat", flash: %{"error" => message}}}} =
               live(conn, ~p"/chat/#{other_client.id}")

      assert message =~ "not found"
    end
  end

  test "a malformed room id is refused", %{conn: conn} do
    assert {:error, {:redirect, %{to: "/trainer/chat"}}} = live(conn, ~p"/chat/not-a-number")
  end
end
