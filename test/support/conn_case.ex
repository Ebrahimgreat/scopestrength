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

defmodule ScopestrengthWeb.ConnCase do
  @moduledoc """
  Test case for tests that go through the endpoint.

  `log_in_user/2` signs a user in on the connection. `log_in_trainer/1` and
  `log_in_client/1` build the trainer or client records the role-gated pages
  need and sign in as them.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint ScopestrengthWeb.Endpoint

      use ScopestrengthWeb, :verified_routes

      import Plug.Conn
      import Phoenix.ConnTest
      import ScopestrengthWeb.ConnCase
    end
  end

  setup tags do
    Scopestrength.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  def register_and_log_in_user(%{conn: conn}) do
    user = Scopestrength.AccountFixtures.user_fixture()
    %{conn: log_in_user(conn, user), user: user}
  end

  def log_in_trainer(%{conn: conn}) do
    trainer = Scopestrength.PeopleFixtures.trainer_fixture()
    %{conn: log_in_user(conn, trainer.user), trainer: trainer, user: trainer.user}
  end

  def log_in_client(%{conn: conn}) do
    client = Scopestrength.PeopleFixtures.client_fixture()
    %{conn: log_in_user(conn, client.user), client: client, user: client.user, trainer: client.trainer}
  end

  def log_in_user(conn, user) do
    token = Scopestrength.Account.generate_user_session_token(user)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, token)
  end
end
