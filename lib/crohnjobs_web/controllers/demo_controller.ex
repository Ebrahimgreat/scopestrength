defmodule CrohnjobsWeb.DemoController do
  use CrohnjobsWeb, :controller

  alias CrohnjobsWeb.UserAuth

  def create(conn, %{"email" => email}) do
    case Reactor.run(CrohnjobsWeb.Demosignupflow.MainFlow, %{email: email}) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Welcome to the demo! Your email: #{user.email} | Password: Demodemo1234")
        |> UserAuth.log_in_user(user)

      {:error, :already_tried} ->
        conn
        |> put_flash(:info, "You've already tried our demo! If you like the service please contact ebrahim@scopestrength.com")
        |> redirect(to: ~p"/users/log_in")

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Failed to create demo account. Please try again.")
        |> redirect(to: ~p"/users/log_in")
    end
  end

  def create(conn, _params) do
    conn
    |> put_flash(:error, "Please enter your email to try the demo.")
    |> redirect(to: ~p"/users/log_in")
  end
end
