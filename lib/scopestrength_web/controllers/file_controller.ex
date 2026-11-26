defmodule ScopestrengthWeb.FileController do
  use ScopestrengthWeb, :controller

  alias Scopestrength.Storage.Access
  alias Scopestrength.Storage

  def show(conn, %{"path" => path}) do
    key = Enum.join(path, "/")

    with true <- Access.authorized?(key, conn.assigns.current_user),
         delivery <- Storage.delivery(key) do
      case delivery do
        {:file, file_path} when is_binary(file_path) ->
          if File.exists?(file_path) do
            conn
            |> put_resp_content_type(MIME.from_path(file_path))
            |> put_resp_header("content-disposition", "inline")
            |> send_file(200, file_path)
          else
            send_resp(conn, :not_found, "Not found")
          end

        {:redirect, url} -> redirect(conn, external: url)
        _ -> send_resp(conn, :not_found, "Not found")
      end
    else
      _ -> send_resp(conn, :not_found, "Not found")
    end
  end

  def show(conn, _params), do: send_resp(conn, :not_found, "Not found")
end
