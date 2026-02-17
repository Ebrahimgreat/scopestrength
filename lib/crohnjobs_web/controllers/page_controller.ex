defmodule CrohnjobsWeb.PageController do
  use CrohnjobsWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end

  def not_found(conn, _params) do
    conn
    |> put_flash(:error, "Page not found.")
    |> redirect(to: ~p"/users/log_in")
  end
end
