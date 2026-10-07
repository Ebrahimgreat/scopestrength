defmodule ScopestrengthWeb.UserRegistrationLiveTest do
  use ScopestrengthWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  setup do
    on_exit(fn -> Application.delete_env(:scopestrength, :registration_enabled) end)
  end

  test "registration is reachable when enabled (the default)", %{conn: conn} do
    Application.put_env(:scopestrength, :registration_enabled, true)
    {:ok, _view, html} = live(conn, ~p"/users/register")
    assert html =~ "Register"
  end

  test "registration redirects to login when disabled", %{conn: conn} do
    Application.put_env(:scopestrength, :registration_enabled, false)

    assert {:error, {:redirect, %{to: "/users/log_in", flash: %{"error" => message}}}} =
             live(conn, ~p"/users/register")

    assert message =~ "Registration is closed"
  end

  test "signing up as a trainer creates the trainer record", %{conn: conn} do
    Application.put_env(:scopestrength, :registration_enabled, true)
    {:ok, view, _html} = live(conn, ~p"/users/register")

    email = "sign#{System.unique_integer([:positive])}@example.com"

    render_submit(view, "save", %{
      "user" => %{
        "name" => "New Trainer",
        "email" => email,
        "password" => "averylongpassword1",
        "role" => "trainer"
      }
    })

    user = Scopestrength.Repo.get_by!(Scopestrength.Account.User, email: email)
    assert Scopestrength.Repo.get_by(Scopestrength.Trainers.Trainer, user_id: user.id)
  end

  test "signing up as a client creates the client record", %{conn: conn} do
    Application.put_env(:scopestrength, :registration_enabled, true)
    {:ok, view, _html} = live(conn, ~p"/users/register")

    email = "sign#{System.unique_integer([:positive])}@example.com"

    render_submit(view, "save", %{
      "user" => %{
        "name" => "New Client",
        "email" => email,
        "password" => "averylongpassword1",
        "role" => "client"
      }
    })

    user = Scopestrength.Repo.get_by!(Scopestrength.Account.User, email: email)
    assert Scopestrength.Repo.get_by(Scopestrength.Clients.Client, user_id: user.id)
  end
end
