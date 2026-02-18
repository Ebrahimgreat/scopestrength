defmodule CrohnjobsWeb.DemoController do
  use CrohnjobsWeb, :controller

  alias Crohnjobs.Account
  alias Crohnjobs.Leads
  alias CrohnjobsWeb.UserAuth

  def create(conn, %{"email" => email}) do
    case Leads.check_lead(email) do
      {:ok, _existing_lead} ->
        # Email already used for demo - show friendly message
        conn
        |> put_flash(:info, "You've already tried our demo! If you like the service please contact ebrahim@scopestrength.com")
        |> redirect(to: ~p"/users/log_in")

      {:error, :not_found} ->
        # New email - create demo account
        case Account.generate_demo_account() do
          {:ok, user} ->
            Leads.create_lead(%{email: email, demo_user_id: user.id})

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

  def create(conn, _params) do
    conn
    |> put_flash(:error, "Please enter your email to try the demo.")
    |> redirect(to: ~p"/users/log_in")
  end
end
