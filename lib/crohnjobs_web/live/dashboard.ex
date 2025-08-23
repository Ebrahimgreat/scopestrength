defmodule CrohnjobsWeb.Dashboard do
  use CrohnjobsWeb, :live_view

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    {:ok, assign(socket, :name, user.name)}

  end


  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do

   ~H"""
   <h1>
   Welcome Back {@name}! How is going


   </h1>
   """

  end

end
