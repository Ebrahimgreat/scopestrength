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

defmodule Scopestrength.ApiTokensTest do
  use Scopestrength.DataCase, async: true

  import Scopestrength.PeopleFixtures

  alias Scopestrength.ApiTokens

  test "every issued token verifies, including prefixes that contain an underscore" do
    client = client_fixture()

    # A random 8-character base64 prefix contains "_" about one time in
    # eight, so 100 tokens all but guarantee that case is exercised.
    for n <- 1..100 do
      {:ok, plaintext, token} =
        ApiTokens.create_token(%{client_id: client.id, user_id: client.user_id, name: "t#{n}"})

      assert {:ok, verified} = ApiTokens.verify_token(plaintext)
      assert verified.id == token.id
    end
  end

  test "rejects malformed and tampered tokens" do
    client = client_fixture()

    {:ok, plaintext, _} =
      ApiTokens.create_token(%{client_id: client.id, user_id: client.user_id, name: "t"})

    assert {:error, _} = ApiTokens.verify_token("sst_short")
    assert {:error, _} = ApiTokens.verify_token("nope")
    assert {:error, _} = ApiTokens.verify_token(plaintext <> "x")
  end
end
