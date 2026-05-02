defmodule ScopestrengthWeb.RoleLayout do
  import Phoenix.LiveView
  import Phoenix.Component

  def on_mount(:default, _params, _session, socket) do
    case socket.assigns.current_user do
      %{role: "trainer"} ->
        {:cont, assign(socket, :layout, {ScopestrengthWeb.Layouts, :trainer})}

      %{role: "client"} ->
        {:cont, assign(socket, :layout, {ScopestrengthWeb.Layouts, :client})}

      _ ->
        {:cont, socket}
    end
  end
end
