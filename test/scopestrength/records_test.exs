defmodule Scopestrength.RecordsTest do
  use Scopestrength.DataCase, async: true

  import Scopestrength.PeopleFixtures
  import Scopestrength.RecordsFixtures

  alias Scopestrength.{ClientNote, ClientWeight, Notifications, ProgressPhotos}

  describe "client notes" do
    test "create, update, list and delete" do
      note = client_note_fixture(%{notes: "Sore shoulder"})
      assert note.id in Enum.map(ClientNote.list_client_notes(), & &1.id)

      {:ok, note} = ClientNote.update_client_notes(note, %{notes: "Better"})
      assert ClientNote.get_client_notes!(note.id).notes == "Better"

      {:ok, _} = ClientNote.delete_client_notes(note)
      assert_raise Ecto.NoResultsError, fn -> ClientNote.get_client_notes!(note.id) end
    end
  end

  describe "client weights" do
    test "upsert_weight/3 updates an entry on the same date" do
      client = client_fixture()
      date = ~D[2026-02-01]

      {:ok, first} = ClientWeight.upsert_weight(client.id, date, "80.0")
      {:ok, second} = ClientWeight.upsert_weight(client.id, date, "79.5")
      assert first.id == second.id
      assert Decimal.equal?(second.weight, Decimal.new("79.5"))

      {:ok, other} = ClientWeight.upsert_weight(client.id, ~D[2026-02-02], "79.0")
      refute other.id == first.id
      assert length(ClientWeight.list_client_weights_for_client(client.id)) == 2
    end

    test "update and delete" do
      weight = client_weight_fixture()
      {:ok, weight} = ClientWeight.update_client_weights(weight, %{weight: "81"})
      assert Decimal.equal?(ClientWeight.get_client_weights!(weight.id).weight, Decimal.new("81"))
      {:ok, _} = ClientWeight.delete_client_weights(weight)
      assert_raise Ecto.NoResultsError, fn -> ClientWeight.get_client_weights!(weight.id) end
    end
  end

  describe "progress photos" do
    test "require a url, date and client" do
      {:error, changeset} = ProgressPhotos.create_progress_photo(%{})
      errors = errors_on(changeset)
      assert errors.photo_url == ["can't be blank"]
      assert errors.date == ["can't be blank"]
      assert errors.client_id == ["can't be blank"]
    end

    test "are scoped to the client" do
      mine = client_fixture()
      theirs = client_fixture()
      photo = progress_photo_fixture(%{client_id: mine.id})
      _other = progress_photo_fixture(%{client_id: theirs.id})

      assert Enum.map(ProgressPhotos.list_progress_photos_for_client(mine.id), & &1.id) == [photo.id]
      assert ProgressPhotos.get_progress_photo_for_client!(photo.id, mine.id).id == photo.id
      assert_raise Ecto.NoResultsError, fn -> ProgressPhotos.get_progress_photo_for_client!(photo.id, theirs.id) end
    end

    test "update and delete" do
      photo = progress_photo_fixture()
      {:ok, photo} = ProgressPhotos.update_progress_photo(photo, %{notes: "Week 2"})
      assert ProgressPhotos.get_progress_photo!(photo.id).notes == "Week 2"
      {:ok, _} = ProgressPhotos.delete_progress_photo(photo)
      assert_raise Ecto.NoResultsError, fn -> ProgressPhotos.get_progress_photo!(photo.id) end
    end
  end

  describe "notifications" do
    test "create, mark read and delete" do
      notification = notification_fixture(%{data: %{workout_id: 5, client_id: 6}})
      assert notification.read_at == nil
      assert notification.data == %{workout_id: 5, client_id: 6}

      now = DateTime.utc_now() |> DateTime.truncate(:second)
      {:ok, read} = Notifications.update_notification(notification, %{read_at: now})
      assert read.read_at == now
      assert notification.id in Enum.map(Notifications.list_notifications(), & &1.id)

      {:ok, _} = Notifications.delete_notification(read)
      assert_raise Ecto.NoResultsError, fn -> Notifications.get_notification!(notification.id) end
    end

    test "data survives a database round trip with string keys" do
      notification = notification_fixture(%{data: %{programme_id: 9}})
      assert Notifications.get_notification!(notification.id).data == %{"programme_id" => 9}
    end
  end
end
