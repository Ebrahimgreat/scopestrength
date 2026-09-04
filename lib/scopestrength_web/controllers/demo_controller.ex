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

defmodule ScopestrengthWeb.DemoController do
  use ScopestrengthWeb, :controller

  alias ScopestrengthWeb.UserAuth

  def create(conn, %{"email" => email}) do
    case Reactor.run(ScopestrengthWeb.Demosignupflow.MainFlow, %{email: email}) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Welcome to the demo! Your email: #{user.email} | Password: Demodemo1234")
        |> UserAuth.log_in_user(user)

      {:error, :already_tried} ->
        conn
        |> put_flash(:info, "You've already tried our demo! If you like the service please contact ebrahim@scopestrength.com")
        |> redirect(to: ~p"/users/log_in")

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Failed to create demo account. Please try again.")
        |> redirect(to: ~p"/users/log_in")
    end
  end

  def create(conn, _params) do
    conn
    |> put_flash(:error, "Please enter your email to try the demo.")
    |> redirect(to: ~p"/users/log_in")
  end
end
