defmodule CrohnjobsWeb.DemoController do
  use CrohnjobsWeb, :controller

  alias Crohnjobs.Account
  alias CrohnjobsWeb.UserAuth

  def create(conn, _params) do
    case Account.generate_demo_account() do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Welcome to the demo! Your email: #{user.email} | Password: Demodemo1234")
        |> UserAuth.log_in_user(user)

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Failed to create demo account. Please try again.")
        |> redirect(to: ~p"/users/log_in")
    end
  end
end
