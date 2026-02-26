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

  def client_report(conn, %{"client_id" => client_id}) do
    client_id = String.to_integer(client_id)

    case Crohnjobs.Reports.ClientReport.generate(client_id) do
      {:ok, file_path, file_name} ->
        conn
        |> put_resp_content_type("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
        |> put_resp_header("content-disposition", "attachment; filename=\"#{file_name}\"")
        |> send_file(200, file_path)

      {:error, _reason} ->
        send_resp(conn, 500, "Failed to generate report")
    end
  end
end
