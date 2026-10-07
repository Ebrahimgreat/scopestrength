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

defmodule ScopestrengthWeb.Plugs.ApiRateLimit do
  @moduledoc """
  Fixed-window rate limiting for the read-only API, keyed by client IP.

  The API is reachable from the internet and a single bearer token grants read
  of one client's whole training history, so a leaked token should not also buy
  unbounded scraping. This runs before authentication, which means it also caps
  how fast someone can guess at tokens.

  Counters live in an ETS table owned by `ScopestrengthWeb.Plugs.ApiRateLimit.Table`.
  State is per node and lost on restart; that is fine for a limiter whose job is
  to blunt bursts rather than to bill anyone.
  """

  import Plug.Conn

  require Logger

  @table :api_rate_limit
  @window_ms :timer.minutes(1)
  @max_requests 60

  def init(opts), do: opts

  def call(conn, opts) do
    limit = Keyword.get(opts, :limit, @max_requests)
    window = Keyword.get(opts, :window_ms, @window_ms)

    case check(bucket_key(conn, window), limit) do
      :ok ->
        conn

      {:error, retry_after_seconds} ->
        conn
        |> put_resp_content_type("application/json")
        |> put_resp_header("retry-after", Integer.to_string(retry_after_seconds))
        |> send_resp(429, Jason.encode!(%{errors: %{detail: "rate limit exceeded"}}))
        |> halt()
    end
  end

  # The window is folded into the key, so old buckets simply stop being read
  # and get swept later rather than needing decrement on every request.
  defp bucket_key(conn, window) do
    window_start = div(System.system_time(:millisecond), window)
    {client_ip(conn), window_start, window}
  end

  defp check(key, limit) do
    count = :ets.update_counter(@table, key, {2, 1}, {key, 0})

    if count > limit do
      {_ip, window_start, window} = key
      elapsed = System.system_time(:millisecond) - window_start * window
      {:error, max(div(window - elapsed, 1000), 1)}
    else
      :ok
    end
  rescue
    ArgumentError ->
      # Table missing (not started, or a test that skips the supervisor). Fail
      # open: the API stays usable and the token is still required.
      Logger.warning("api rate limit table unavailable; request not counted")
      :ok
  end

  # Behind a reverse proxy the peer is the proxy, so prefer the forwarded
  # address when one is present.
  defp client_ip(conn) do
    case get_req_header(conn, "x-forwarded-for") do
      [value | _] ->
        value |> String.split(",") |> List.first() |> String.trim()

      [] ->
        conn.remote_ip |> :inet.ntoa() |> to_string()
    end
  end

  defmodule Table do
    @moduledoc """
    Owns the rate-limiter ETS table and sweeps expired buckets.
    """

    use GenServer

    @table :api_rate_limit
    @sweep_every :timer.minutes(5)

    def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

    @impl true
    def init(_opts) do
      :ets.new(@table, [:set, :public, :named_table, write_concurrency: true])
      schedule_sweep()
      {:ok, %{}}
    end

    @impl true
    def handle_info(:sweep, state) do
      # Drop every bucket whose window has already closed.
      now = System.system_time(:millisecond)

      :ets.select_delete(@table, [
        {{{:_, :"$1", :"$2"}, :_}, [{:<, {:*, {:+, :"$1", 1}, :"$2"}, now}], [true]}
      ])

      schedule_sweep()
      {:noreply, state}
    end

    defp schedule_sweep, do: Process.send_after(self(), :sweep, @sweep_every)
  end
end
