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

defmodule ScopestrengthWeb.McpController do
  @moduledoc """
  A minimal MCP server over Streamable HTTP, answering JSON-RPC with plain JSON
  (no SSE stream; the spec allows a server to reply that way).

  It exposes tools only. Everything a tool touches is scoped to the client the
  token resolved to; see `ScopestrengthWeb.Mcp.Tools`.
  """

  use ScopestrengthWeb, :controller

  require Logger

  alias ScopestrengthWeb.Mcp.Tools

  @supported_versions ["2025-06-18", "2025-03-26", "2024-11-05"]
  @latest_version "2025-06-18"

  def handle(conn, _params) do
    ctx = %{
      user: conn.assigns.current_user,
      client: conn.assigns.current_client,
      token: conn.assigns.api_token
    }

    # Use body_params, not params: params also carries the path token.
    case conn.body_params do
      %{"_json" => batch} when is_list(batch) ->
        batch
        |> Enum.map(&dispatch(&1, ctx))
        |> Enum.reject(&is_nil/1)
        |> reply(conn)

      message ->
        message |> dispatch(ctx) |> reply(conn)
    end
  end

  # GET would open a server-to-client SSE stream; this server never sends
  # unprompted messages, so it declines as the spec allows.
  def method_not_allowed(conn, _params) do
    conn
    |> put_resp_header("allow", "POST")
    |> send_resp(405, "")
  end

  defp reply(nil, conn), do: send_resp(conn, 202, "")
  defp reply([], conn), do: send_resp(conn, 202, "")
  defp reply(body, conn), do: json(conn, body)

  # A request (has an id) gets a response; a notification gets nothing.
  defp dispatch(%{"jsonrpc" => "2.0", "method" => method} = message, ctx)
       when is_binary(method) do
    if Map.has_key?(message, "id") do
      id = message["id"]

      case handle_method(method, Map.get(message, "params") || %{}, ctx) do
        {:ok, result} -> %{jsonrpc: "2.0", id: id, result: result}
        {:error, code, msg} -> %{jsonrpc: "2.0", id: id, error: %{code: code, message: msg}}
      end
    end
  end

  # A response from the client to a server request; this server makes none.
  defp dispatch(%{"jsonrpc" => "2.0", "id" => _}, _ctx), do: nil

  defp dispatch(_message, _ctx) do
    %{jsonrpc: "2.0", id: nil, error: %{code: -32600, message: "Invalid Request"}}
  end

  defp handle_method("initialize", params, _ctx) do
    requested = params["protocolVersion"]
    version = if requested in @supported_versions, do: requested, else: @latest_version

    {:ok,
     %{
       protocolVersion: version,
       capabilities: %{tools: %{listChanged: false}},
       serverInfo: %{
         name: "scopestrength",
         title: "ScopeStrength",
         version: to_string(Application.spec(:scopestrength, :vsn))
       },
       instructions: Tools.instructions()
     }}
  end

  defp handle_method("ping", _params, _ctx), do: {:ok, %{}}

  defp handle_method("tools/list", _params, _ctx), do: {:ok, %{tools: Tools.definitions()}}

  defp handle_method("tools/call", %{"name" => name} = params, ctx) when is_binary(name) do
    arguments =
      case Map.get(params, "arguments") do
        args when is_map(args) -> args
        _ -> %{}
      end

    case safe_call(name, arguments, ctx) do
      {:ok, data} ->
        {:ok, %{content: [%{type: "text", text: Jason.encode!(data)}], isError: false}}

      {:error, message} ->
        {:ok, %{content: [%{type: "text", text: message}], isError: true}}

      :unknown_tool ->
        {:error, -32602, "Unknown tool: #{name}"}
    end
  end

  defp handle_method("tools/call", _params, _ctx),
    do: {:error, -32602, "tools/call needs a tool name"}

  defp handle_method(method, _params, _ctx),
    do: {:error, -32601, "Method not found: #{method}"}

  # A bug in one tool should come back as a tool error the assistant can
  # report, not a 500 that looks like the server is down.
  defp safe_call(name, arguments, ctx) do
    Tools.call(name, arguments, ctx)
  rescue
    exception ->
      Logger.error(
        "MCP tool #{name} crashed: " <> Exception.format(:error, exception, __STACKTRACE__)
      )

      {:error, "ScopeStrength hit an internal error running #{name}."}
  end
end
