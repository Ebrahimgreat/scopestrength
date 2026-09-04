# ScopeStrength - personal trainer management application
# Copyright (C) 2026  Ebrahim Shahid Arshad
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# SPDX-License-Identifier: AGPL-3.0-or-later

defmodule ScopestrengthWeb.DownloadController do
  use ScopestrengthWeb, :controller

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

    {:ok, file_path, file_name} = Scopestrength.Reports.ClientReport.generate(client_id)

    conn
    |> put_resp_content_type("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
    |> put_resp_header("content-disposition", "attachment; filename=\"#{file_name}\"")
    |> send_file(200, file_path)
  end
end
