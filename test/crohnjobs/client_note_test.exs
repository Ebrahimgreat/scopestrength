defmodule Crohnjobs.ClientNoteTest do
  use Crohnjobs.DataCase

  alias Crohnjobs.ClientNote

  describe "client_notes" do
    alias Crohnjobs.ClientNote.ClientNotes

    import Crohnjobs.ClientNoteFixtures

    @invalid_attrs %{}

    test "list_client_notes/0 returns all client_notes" do
      client_notes = client_notes_fixture()
      assert ClientNote.list_client_notes() == [client_notes]
    end

    test "get_client_notes!/1 returns the client_notes with given id" do
      client_notes = client_notes_fixture()
      assert ClientNote.get_client_notes!(client_notes.id) == client_notes
    end

    test "create_client_notes/1 with valid data creates a client_notes" do
      valid_attrs = %{}

      assert {:ok, %ClientNotes{} = client_notes} = ClientNote.create_client_notes(valid_attrs)
    end

    test "create_client_notes/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = ClientNote.create_client_notes(@invalid_attrs)
    end

    test "update_client_notes/2 with valid data updates the client_notes" do
      client_notes = client_notes_fixture()
      update_attrs = %{}

      assert {:ok, %ClientNotes{} = client_notes} = ClientNote.update_client_notes(client_notes, update_attrs)
    end

    test "update_client_notes/2 with invalid data returns error changeset" do
      client_notes = client_notes_fixture()
      assert {:error, %Ecto.Changeset{}} = ClientNote.update_client_notes(client_notes, @invalid_attrs)
      assert client_notes == ClientNote.get_client_notes!(client_notes.id)
    end

    test "delete_client_notes/1 deletes the client_notes" do
      client_notes = client_notes_fixture()
      assert {:ok, %ClientNotes{}} = ClientNote.delete_client_notes(client_notes)
      assert_raise Ecto.NoResultsError, fn -> ClientNote.get_client_notes!(client_notes.id) end
    end

    test "change_client_notes/1 returns a client_notes changeset" do
      client_notes = client_notes_fixture()
      assert %Ecto.Changeset{} = ClientNote.change_client_notes(client_notes)
    end
  end
end
