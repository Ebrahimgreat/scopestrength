defmodule ScopestrengthWeb.Todos do
  use ScopestrengthWeb, :live_view
  def mount(_params, _session, socket) do
    {:ok, assign(socket, todos: [], new_todo: "")}

  end

end
