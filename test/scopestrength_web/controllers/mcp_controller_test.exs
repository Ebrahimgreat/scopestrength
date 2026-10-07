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

defmodule ScopestrengthWeb.McpControllerTest do
  use ScopestrengthWeb.ConnCase, async: true

  import Scopestrength.ExercisesFixtures
  import Scopestrength.PeopleFixtures
  import Scopestrength.ProgrammesFixtures
  import Scopestrength.TrainingFixtures

  alias Scopestrength.ApiTokens
  alias Scopestrength.ClientProgressions
  alias Scopestrength.Programmes

  setup do
    client = client_fixture()
    bench = exercise_fixture(%{name: "Bench Press #{System.unique_integer([:positive])}"})
    row = exercise_fixture(%{name: "Barbell Row #{System.unique_integer([:positive])}"})

    programme = programme_fixture(%{user_id: client.trainer.user_id, name: "PPL"})
    push = programme_template_fixture(%{programme_id: programme.id, name: "Push"})
    pull = programme_template_fixture(%{programme_id: programme.id, name: "Pull"})
    programme_details_fixture(%{programme_template_id: push.id, exercise_id: bench.id, set: "3"})
    programme_details_fixture(%{programme_template_id: pull.id, exercise_id: row.id, set: "3"})
    {:ok, _} = Programmes.assign_client_to_programme(programme.id, client.id)

    {:ok, rw, _} =
      ApiTokens.create_token(%{
        client_id: client.id,
        user_id: client.user_id,
        name: "claude",
        scope: "read_write"
      })

    {:ok, ro, _} =
      ApiTokens.create_token(%{client_id: client.id, user_id: client.user_id, name: "ro"})

    %{client: client, bench: bench, row: row, programme: programme, rw: rw, ro: ro}
  end

  defp rpc(conn, token, method, params \\ %{}) do
    conn
    |> put_req_header("content-type", "application/json")
    |> put_req_header("accept", "application/json, text/event-stream")
    |> post(
      "/mcp/#{token}",
      Jason.encode!(%{jsonrpc: "2.0", id: 1, method: method, params: params})
    )
  end

  defp tool(conn, token, name, args \\ %{}) do
    response =
      conn |> rpc(token, "tools/call", %{name: name, arguments: args}) |> json_response(200)

    result = response["result"]
    [%{"type" => "text", "text" => text}] = result["content"]
    if result["isError"], do: {:error, text}, else: {:ok, Jason.decode!(text)}
  end

  describe "protocol" do
    test "initialize negotiates a version and advertises tools", %{conn: conn, rw: rw} do
      body =
        conn
        |> rpc(rw, "initialize", %{protocolVersion: "2025-06-18", capabilities: %{}})
        |> json_response(200)

      assert body["result"]["protocolVersion"] == "2025-06-18"
      assert body["result"]["capabilities"]["tools"]
      assert body["result"]["instructions"] =~ "progress"
    end

    test "an unknown protocol version gets the latest supported", %{conn: conn, rw: rw} do
      body = conn |> rpc(rw, "initialize", %{protocolVersion: "1999-01-01"}) |> json_response(200)
      assert body["result"]["protocolVersion"] == "2025-06-18"
    end

    test "notifications get 202 and no body", %{conn: conn, rw: rw} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post(
          "/mcp/#{rw}",
          Jason.encode!(%{jsonrpc: "2.0", method: "notifications/initialized"})
        )

      assert conn.status == 202
    end

    test "tools/list lists every tool", %{conn: conn, rw: rw} do
      names =
        conn
        |> rpc(rw, "tools/list")
        |> json_response(200)
        |> get_in(["result", "tools"])
        |> Enum.map(& &1["name"])

      for name <- ~w(get_programme list_programmes recent_workouts exercise_history
                     search_exercises log_workout add_sets delete_workout) do
        assert name in names
      end
    end

    test "unknown methods and tools are JSON-RPC errors", %{conn: conn, rw: rw} do
      assert %{"error" => %{"code" => -32601}} =
               conn |> rpc(rw, "resources/list") |> json_response(200)

      assert %{"error" => %{"code" => -32602}} =
               conn |> rpc(rw, "tools/call", %{name: "nope"}) |> json_response(200)
    end

    test "GET is not allowed", %{conn: conn, rw: rw} do
      assert get(conn, "/mcp/#{rw}").status == 405
    end
  end

  describe "auth" do
    test "rejects a wrong token", %{conn: conn, rw: rw} do
      assert conn |> rpc(rw <> "x", "tools/list") |> json_response(401)
    end

    test "rejects a revoked token", %{conn: conn, client: client, rw: rw} do
      {:ok, token} = ApiTokens.verify_token(rw)
      {:ok, _} = ApiTokens.revoke_token(client.id, token.id)
      assert conn |> rpc(rw, "tools/list") |> json_response(401)
    end

    test "accepts a bearer header on /mcp", %{conn: conn, rw: rw} do
      body =
        conn
        |> put_req_header("authorization", "Bearer " <> rw)
        |> put_req_header("content-type", "application/json")
        |> post("/mcp", Jason.encode!(%{jsonrpc: "2.0", id: 7, method: "ping"}))
        |> json_response(200)

      assert body == %{"jsonrpc" => "2.0", "id" => 7, "result" => %{}}
    end

    test "rejects /mcp with no token", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/mcp", Jason.encode!(%{jsonrpc: "2.0", id: 1, method: "ping"}))

      assert json_response(conn, 401)
    end

    test "a read-only token cannot log", %{conn: conn, ro: ro, bench: bench} do
      assert {:error, msg} =
               tool(conn, ro, "log_workout", %{
                 name: "Push",
                 sets: [%{exercise_id: bench.id, reps: 8, weight: 60}]
               })

      assert msg =~ "read-only"
      assert {:ok, %{"workouts" => []}} = tool(conn, ro, "recent_workouts")
    end
  end

  describe "programme" do
    test "defaults to the active programme with every day", %{conn: conn, rw: rw, bench: bench} do
      assert {:ok, programme} = tool(conn, rw, "get_programme")
      assert programme["name"] == "PPL"
      assert Enum.map(programme["days"], & &1["name"]) == ["Push", "Pull"]

      [push | _] = programme["days"]
      assert [%{"exercise_id" => id, "sets" => 3, "reps" => "8-12"}] = push["exercises"]
      assert id == bench.id
    end

    test "filters to one day", %{conn: conn, rw: rw} do
      assert {:ok, %{"days" => [%{"name" => "Pull"}]}} =
               tool(conn, rw, "get_programme", %{day: "pull"})

      assert {:error, msg} = tool(conn, rw, "get_programme", %{day: "legs"})
      assert msg =~ "Push, Pull"
    end

    test "does not show a programme the client was never assigned", %{conn: conn, rw: rw} do
      other = programme_fixture()
      assert {:error, msg} = tool(conn, rw, "get_programme", %{programme_id: other.id})
      assert msg =~ "not found"
    end

    test "list_programmes marks the active one", %{conn: conn, rw: rw, programme: programme} do
      assert {:ok, %{"active_programme_id" => id, "programmes" => [p]}} =
               tool(conn, rw, "list_programmes")

      assert id == programme.id
      assert p["active"]
      assert length(p["days"]) == 2
    end
  end

  describe "logging" do
    test "logs a session, numbers sets per exercise and updates progression",
         %{conn: conn, rw: rw, client: client, bench: bench, row: row} do
      assert {:ok, %{"logged" => logged}} =
               tool(conn, rw, "log_workout", %{
                 name: "Push",
                 date: "2026-10-07",
                 sets: [
                   %{exercise: String.upcase(bench.name), reps: 12, weight: 60},
                   %{exercise_id: row.id, reps: 10, weight: 50},
                   %{exercise_id: bench.id, reps: 9, weight: 60}
                 ]
               })

      assert logged["date"] == "2026-10-07"
      [b, r] = logged["exercises"]
      assert b["exercise_id"] == bench.id
      assert Enum.map(b["sets"], & &1["set"]) == [1, 2]
      assert [%{"set" => 1, "reps" => 10, "weight" => 50}] = r["sets"]

      # Same path as saving in the app: progression rows now exist.
      assert [_ | _] =
               ClientProgressions.get_client_progression_with_exercise(client.id, bench.id)

      assert {:ok, %{"days" => [push]}} = tool(conn, rw, "get_programme", %{day: "Push"})
      [ex] = push["exercises"]
      assert ex["last_time"]["date"] == "2026-10-07"
      assert length(ex["last_time"]["sets"]) == 2
      assert [%{"set" => 1, "target_weight" => 60} | _] = ex["targets"]
    end

    test "add_sets continues numbering and stays scoped to the client",
         %{conn: conn, rw: rw, bench: bench} do
      {:ok, %{"logged" => %{"workout_id" => id}}} =
        tool(conn, rw, "log_workout", %{
          name: "Push",
          sets: [%{exercise_id: bench.id, reps: 8, weight: 60}]
        })

      assert {:ok, %{"workout" => w}} =
               tool(conn, rw, "add_sets", %{
                 workout_id: id,
                 sets: [%{exercise_id: bench.id, reps: 7, weight: 60}]
               })

      assert [%{"sets" => [%{"set" => 1}, %{"set" => 2}]}] = w["exercises"]

      someone_else = workout_fixture(%{client_id: client_fixture().id})

      assert {:error, msg} =
               tool(conn, rw, "add_sets", %{
                 workout_id: someone_else.id,
                 sets: [%{exercise_id: bench.id, reps: 1}]
               })

      assert msg =~ "not found"
      assert {:error, _} = tool(conn, rw, "delete_workout", %{workout_id: someone_else.id})
    end

    test "rejects an unknown exercise name with suggestions and saves nothing",
         %{conn: conn, rw: rw, bench: bench} do
      assert {:error, msg} =
               tool(conn, rw, "log_workout", %{
                 name: "Push",
                 sets: [
                   %{exercise_id: bench.id, reps: 8, weight: 60},
                   %{exercise: "Bench", reps: 8}
                 ]
               })

      assert msg =~ "Set 2"
      assert msg =~ bench.name
      assert {:ok, %{"workouts" => []}} = tool(conn, rw, "recent_workouts")
    end

    test "rejects bad input", %{conn: conn, rw: rw, bench: bench} do
      assert {:error, _} = tool(conn, rw, "log_workout", %{name: "Push", sets: []})

      assert {:error, msg} =
               tool(conn, rw, "log_workout", %{
                 name: "Push",
                 sets: [%{exercise_id: bench.id, reps: "lots"}]
               })

      assert msg =~ "reps"

      assert {:error, _} =
               tool(conn, rw, "log_workout", %{
                 name: "Push",
                 date: "yesterday",
                 sets: [%{exercise_id: bench.id, reps: 5}]
               })
    end

    test "history and delete", %{conn: conn, rw: rw, bench: bench} do
      {:ok, %{"logged" => %{"workout_id" => id}}} =
        tool(conn, rw, "log_workout", %{
          name: "Push",
          sets: [%{exercise_id: bench.id, reps: 8, weight: 62.5}]
        })

      assert {:ok, %{"sessions" => [s]}} =
               tool(conn, rw, "exercise_history", %{exercise: bench.name})

      assert [%{"weight" => 62.5, "reps" => 8}] = s["sets"]

      assert {:ok, %{"exercises" => [_ | _]}} =
               tool(conn, rw, "search_exercises", %{query: "bench press"})

      assert {:ok, %{"deleted_workout_id" => ^id}} =
               tool(conn, rw, "delete_workout", %{workout_id: id})

      assert {:ok, %{"workouts" => []}} = tool(conn, rw, "recent_workouts")
    end
  end
end
