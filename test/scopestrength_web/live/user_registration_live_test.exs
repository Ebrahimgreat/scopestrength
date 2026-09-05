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
end
