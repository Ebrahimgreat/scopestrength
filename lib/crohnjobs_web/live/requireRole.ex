defmodule CrohnjobsWeb.RequireRole do
  import Phoenix.LiveView
  import Phoenix.LiveView.Helpers

  @moduledoc """
  LiveView on_mount hook to enforce user roles.

  Usage:
      on_mount {CrohnjobsWeb.RequireRole, "trainer"}
      on_mount {CrohnjobsWeb.RequireRole, "client"}
  """

  def on_mount(role, _params, _session, socket) when is_binary(role) do
    case socket.assigns.current_user do
      nil ->
        {:halt, redirect(socket, to: "/login")}

      %{role: ^role} ->
        {:cont, socket} # allowed

      _ ->
        # user logged in but wrong role
        target = if role == "trainer", do: "/client", else: "/trainer"
        {:halt, push_navigate(socket, to: target)}
    end
  end
end
