defmodule ScopestrengthWeb.DownloadControllerTest do
  use ScopestrengthWeb.ConnCase, async: false

  import Scopestrength.PeopleFixtures

  alias Scopestrength.ProgressPhotos
  alias Scopestrength.Storage

  setup %{conn: conn} do
    root = Path.join(System.tmp_dir!(), "scopestrength-download-#{System.unique_integer([:positive])}")
    previous = Application.get_env(:scopestrength, :storage)
    Application.put_env(:scopestrength, :storage, adapter: Storage.Local, local_root: root)

    on_exit(fn ->
      File.rm_rf!(root)
      if previous, do: Application.put_env(:scopestrength, :storage, previous), else: Application.delete_env(:scopestrength, :storage)
    end)

    {:ok, conn: conn, root: root}
  end

  test "anonymous users cannot fetch a private file", %{conn: conn} do
    assert redirected_to(get(conn, "/files/progress_photos/missing.jpg")) == "/users/log_in"
  end

  test "the file owner can fetch a progress photo", %{conn: conn, root: root} do
    client = client_fixture()
    key = "progress_photos/owner.jpg"
    File.mkdir_p!(Path.dirname(Path.join(root, key)))
    File.write!(Path.join(root, key), "private photo")
    {:ok, _photo} = ProgressPhotos.create_progress_photo(progress_photo_attrs(client.id, key))

    assert response(log_in_user(conn, client.user) |> get("/files/#{key}"), 200) == "private photo"
  end

  test "a different trainer cannot fetch another trainer's photo", %{conn: conn, root: root} do
    client = client_fixture()
    other_trainer = trainer_fixture()
    key = "progress_photos/cross-trainer.jpg"
    File.mkdir_p!(Path.dirname(Path.join(root, key)))
    File.write!(Path.join(root, key), "private photo")
    {:ok, _photo} = ProgressPhotos.create_progress_photo(progress_photo_attrs(client.id, key))

    assert response(log_in_user(conn, other_trainer.user) |> get("/files/#{key}"), 404) == "Not found"
  end

  test "another client cannot fetch a client's photo", %{conn: conn, root: root} do
    client = client_fixture()
    other_client = client_fixture(%{trainer: client.trainer})
    key = "progress_photos/cross-client.jpg"
    File.mkdir_p!(Path.dirname(Path.join(root, key)))
    File.write!(Path.join(root, key), "private photo")
    {:ok, _photo} = ProgressPhotos.create_progress_photo(progress_photo_attrs(client.id, key))

    assert response(log_in_user(conn, other_client.user) |> get("/files/#{key}"), 404) == "Not found"
  end

  test "the owning trainer can fetch the client's photo", %{conn: conn, root: root} do
    client = client_fixture()
    key = "progress_photos/trainer.jpg"
    File.mkdir_p!(Path.dirname(Path.join(root, key)))
    File.write!(Path.join(root, key), "private photo")
    {:ok, _photo} = ProgressPhotos.create_progress_photo(progress_photo_attrs(client.id, key))

    assert response(log_in_user(conn, client.trainer.user) |> get("/files/#{key}"), 200) == "private photo"
  end

  test "only the owning trainer can download a client report", %{conn: conn} do
    client = client_fixture()
    other_trainer = trainer_fixture()

    assert response(log_in_user(conn, other_trainer.user) |> get("/download/client-report/#{client.id}"), 404) ==
             "Client report not found"

    assert response(log_in_user(Phoenix.ConnTest.build_conn(), client.user) |> get("/download/client-report/#{client.id}"), 404) ==
             "Client report not found"

    assert response(log_in_user(Phoenix.ConnTest.build_conn(), client.trainer.user) |> get("/download/client-report/#{client.id}"), 200) !=
             "Client report not found"
  end

  defp progress_photo_attrs(client_id, key) do
    %{client_id: client_id, photo_url: key, date: DateTime.utc_now()}
  end
end
