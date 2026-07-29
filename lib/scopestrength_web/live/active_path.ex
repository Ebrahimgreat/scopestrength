defmodule ScopestrengthWeb.ActivePath do
  @moduledoc """
  LiveView on_mount hook that keeps `@active_path` in sync with the current URL.

  The sidebar needs to know which nav item to highlight. LiveView navigation
  doesn't remount, so this attaches to `handle_params` rather than assigning
  once at mount.

  Usage:
      on_mount ScopestrengthWeb.ActivePath
  """

  import Phoenix.LiveView
  import Phoenix.Component

  def on_mount(:default, _params, _session, socket) do
    {:cont,
     socket
     |> assign_new(:active_path, fn -> nil end)
     |> attach_hook(:active_path, :handle_params, &set_active_path/3)}
  end

  defp set_active_path(_params, url, socket) do
    {:cont, assign(socket, :active_path, URI.parse(url).path)}
  end
end
