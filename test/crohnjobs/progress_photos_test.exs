defmodule Crohnjobs.ProgressPhotosTest do
  use Crohnjobs.DataCase

  alias Crohnjobs.ProgressPhotos

  describe "progress_photos" do
    alias Crohnjobs.ProgressPhotos.ProgressPhoto

    import Crohnjobs.ProgressPhotosFixtures

    @invalid_attrs %{date: nil, photo_url: nil, notes: nil}

    test "list_progress_photos/0 returns all progress_photos" do
      progress_photo = progress_photo_fixture()
      assert ProgressPhotos.list_progress_photos() == [progress_photo]
    end

    test "get_progress_photo!/1 returns the progress_photo with given id" do
      progress_photo = progress_photo_fixture()
      assert ProgressPhotos.get_progress_photo!(progress_photo.id) == progress_photo
    end

    test "create_progress_photo/1 with valid data creates a progress_photo" do
      valid_attrs = %{date: ~U[2026-01-31 12:34:00Z], photo_url: "some photo_url", notes: "some notes"}

      assert {:ok, %ProgressPhoto{} = progress_photo} = ProgressPhotos.create_progress_photo(valid_attrs)
      assert progress_photo.date == ~U[2026-01-31 12:34:00Z]
      assert progress_photo.photo_url == "some photo_url"
      assert progress_photo.notes == "some notes"
    end

    test "create_progress_photo/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = ProgressPhotos.create_progress_photo(@invalid_attrs)
    end

    test "update_progress_photo/2 with valid data updates the progress_photo" do
      progress_photo = progress_photo_fixture()
      update_attrs = %{date: ~U[2026-02-01 12:34:00Z], photo_url: "some updated photo_url", notes: "some updated notes"}

      assert {:ok, %ProgressPhoto{} = progress_photo} = ProgressPhotos.update_progress_photo(progress_photo, update_attrs)
      assert progress_photo.date == ~U[2026-02-01 12:34:00Z]
      assert progress_photo.photo_url == "some updated photo_url"
      assert progress_photo.notes == "some updated notes"
    end

    test "update_progress_photo/2 with invalid data returns error changeset" do
      progress_photo = progress_photo_fixture()
      assert {:error, %Ecto.Changeset{}} = ProgressPhotos.update_progress_photo(progress_photo, @invalid_attrs)
      assert progress_photo == ProgressPhotos.get_progress_photo!(progress_photo.id)
    end

    test "delete_progress_photo/1 deletes the progress_photo" do
      progress_photo = progress_photo_fixture()
      assert {:ok, %ProgressPhoto{}} = ProgressPhotos.delete_progress_photo(progress_photo)
      assert_raise Ecto.NoResultsError, fn -> ProgressPhotos.get_progress_photo!(progress_photo.id) end
    end

    test "change_progress_photo/1 returns a progress_photo changeset" do
      progress_photo = progress_photo_fixture()
      assert %Ecto.Changeset{} = ProgressPhotos.change_progress_photo(progress_photo)
    end
  end
end
