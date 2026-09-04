defmodule Scopestrength.StorageTest do
  use ExUnit.Case, async: false

  alias Scopestrength.Storage

  setup do
    root = Path.join(System.tmp_dir!(), "scopestrength-storage-#{System.unique_integer([:positive])}")
    previous = Application.get_env(:scopestrength, :storage)
    Application.put_env(:scopestrength, :storage, adapter: Storage.Local, local_root: root)

    on_exit(fn ->
      File.rm_rf!(root)
      if previous, do: Application.put_env(:scopestrength, :storage, previous), else: Application.delete_env(:scopestrength, :storage)
    end)

    %{root: root}
  end

  test "put/3 copies the file under the prefix and returns a key", %{root: root} do
    source = Path.join(root, "source.txt")
    File.mkdir_p!(root)
    File.write!(source, "photo bytes")

    assert {:ok, "progress_photos/abc.txt"} = Storage.put(source, "progress_photos", "abc.txt")
    assert File.read!(Path.join([root, "progress_photos", "abc.txt"])) == "photo bytes"
  end

  test "url/1 derives a browser path and passes legacy values through" do
    assert Storage.url("progress_photos/abc.jpg") == "/uploads/progress_photos/abc.jpg"
    assert Storage.url("/uploads/old.jpg") == "/uploads/old.jpg"
    assert Storage.url("https://cdn.example.com/x.jpg") == "https://cdn.example.com/x.jpg"
    assert Storage.url(nil) == nil
  end

  test "delete/1 removes the object and tolerates missing ones", %{root: root} do
    source = Path.join(root, "s.txt")
    File.mkdir_p!(root)
    File.write!(source, "x")
    {:ok, key} = Storage.put(source, "chat", "s.txt")

    assert :ok = Storage.delete(key)
    refute File.exists?(Path.join(root, key))
    assert :ok = Storage.delete("chat/never-there.txt")
    assert :ok = Storage.delete(nil)
  end

  test "local disk cannot sign direct uploads" do
    refute Storage.direct_upload?()
    assert {:error, :not_supported} = Storage.presigned_put("chat/x.jpg", "image/jpeg")
  end
end
