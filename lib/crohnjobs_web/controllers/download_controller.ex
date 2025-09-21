defmodule CrohnjobsWeb.DownloadController do
  use CrohnjobsWeb, :controller

  def workout(conn, _params) do
    file_path = "programme.txt"

    if File.exists?(file_path) do
      conn
      |> put_resp_content_type("text/plain")
      |> put_resp_header("content-disposition", "attachment; filename=\"workout.txt\"")
      |> send_file(200, file_path)
    else
      send_resp(conn, 404, "Workout file not found")
    end
  end
end
