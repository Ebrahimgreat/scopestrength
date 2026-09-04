defmodule Scopestrength.ChatTest do
  use Scopestrength.DataCase, async: true

  import Scopestrength.AccountFixtures
  import Scopestrength.RecordsFixtures

  alias Scopestrength.Chat
  alias Scopestrength.Chat.Attachment

  @stored %{file_url: "chat/a.jpg", file_name: "a.jpg", content_type: "image/jpeg", file_size: 10}
  @pending %{file_name: "b.pdf", content_type: "application/pdf", file_size: 20}

  test "messages need a room and a user" do
    {:error, changeset} = Chat.create_message(%{text: "hi"})
    assert %{room_id: ["can't be blank"], user_id: ["can't be blank"]} = errors_on(changeset)
  end

  test "create, update, list and delete a message" do
    message = message_fixture(%{text: "hello"})
    {:ok, message} = Chat.update_message(message, %{text: "edited"})
    assert Chat.get_message!(message.id).text == "edited"
    assert message.id in Enum.map(Chat.list_messages(), & &1.id)
    {:ok, _} = Chat.delete_message(message)
    assert_raise Ecto.NoResultsError, fn -> Chat.get_message!(message.id) end
  end

  test "create_message_with_attachments/2 stores uploaded files in one transaction" do
    user = user_fixture()
    {:ok, message} = Chat.create_message_with_attachments(%{user_id: user.id, room_id: "1"}, [@stored])
    assert message.text == ""

    [attachment] = Repo.preload(message, :attachments).attachments
    assert attachment.status == "uploaded"
    assert attachment.file_url == "chat/a.jpg"
  end

  test "pending attachments can be completed or failed" do
    user = user_fixture()
    {:ok, {message, [pending]}} = Chat.create_message_with_pending_attachments(%{user_id: user.id, room_id: "1"}, [@pending])
    assert %Attachment{status: "pending", file_url: nil, message_id: message_id} = pending
    assert message_id == message.id

    {:ok, uploaded} = Chat.mark_attachment_uploaded(pending, "chat/b.pdf")
    assert uploaded.status == "uploaded"
    assert uploaded.file_url == "chat/b.pdf"

    {:ok, failed} = Chat.mark_attachment_failed(uploaded)
    assert failed.status == "failed"
    assert Chat.get_attachment(failed.id).status == "failed"
    refute Chat.get_attachment(-1)
  end

  test "create_message_with_mixed_attachments/3 handles both kinds" do
    user = user_fixture()

    {:ok, {message, pending_rows}} =
      Chat.create_message_with_mixed_attachments(%{user_id: user.id, room_id: "1", text: "files"}, [@stored], [@pending])

    assert [%Attachment{status: "pending"}] = pending_rows
    statuses = message |> Repo.preload(:attachments) |> Map.fetch!(:attachments) |> Enum.map(& &1.status) |> Enum.sort()
    assert statuses == ["pending", "uploaded"]
  end

  test "a failing message rolls back its attachments" do
    assert {:error, %Ecto.Changeset{}} = Chat.create_message_with_attachments(%{room_id: "1"}, [@stored])
    assert Repo.aggregate(Attachment, :count) == 0
  end
end
