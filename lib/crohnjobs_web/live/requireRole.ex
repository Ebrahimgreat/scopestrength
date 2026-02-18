defmodule CrohnjobsWeb.RequireRole do
  import Phoenix.LiveView

  @moduledoc """
  LiveView on_mount hook to enforce user roles.

  Usage:
      on_mount {CrohnjobsWeb.RequireRole, "trainer"}
      on_mount {CrohnjobsWeb.RequireRole, "client"}
      on_mount {CrohnjobsWeb.RequireRole, "admin"}
  """

  def on_mount(role, _params, _session, socket) when is_binary(role) do
    case socket.assigns.current_user do
      nil ->
        {:halt, redirect(socket, to: "/users/log_in")}

      %{role: ^role} ->
        {:cont, socket}

      %{role: user_role} ->
        target = role_home(user_role)
        {:halt, push_navigate(socket, to: target)}
    end
  end

  defp role_home("admin"), do: "/admin"
  defp role_home("trainer"), do: "/trainer"
  defp role_home("client"), do: "/client"
  defp role_home(_), do: "/users/log_in"
end
