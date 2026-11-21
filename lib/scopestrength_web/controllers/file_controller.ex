defmodule ScopestrengthWeb.FileController do
  use ScopestrengthWeb, :controller

  alias Scopestrength.Storage.Access
  alias Scopestrength.Storage.Local

  def show(conn, %{"path" => path}) do
    key = Enum.join(path, "/")

    with true <- Access.authorized?(key, conn.assigns.current_user),
         {:ok, file_path} <- Local.path(key),
         true <- File.exists?(file_path) do
      conn
      |> put_resp_content_type(MIME.from_path(file_path))
      |> put_resp_header("content-disposition", "inline")
      |> send_file(200, file_path)
    else
      _ -> send_resp(conn, :not_found, "Not found")
    end
  end

  def show(conn, _params), do: send_resp(conn, :not_found, "Not found")
end
