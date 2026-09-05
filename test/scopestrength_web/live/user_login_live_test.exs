defmodule ScopestrengthWeb.UserLoginLiveTest do
  use ScopestrengthWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  setup do
    on_exit(fn -> Application.delete_env(:scopestrength, :registration_enabled) end)
  end

  test "shows the sign up link when registration is enabled (the default)", %{conn: conn} do
    Application.put_env(:scopestrength, :registration_enabled, true)
    {:ok, _view, html} = live(conn, ~p"/users/log_in")
    assert html =~ "Sign up"
  end

  test "hides the sign up link when registration is disabled", %{conn: conn} do
    Application.put_env(:scopestrength, :registration_enabled, false)
    {:ok, _view, html} = live(conn, ~p"/users/log_in")
    refute html =~ "Sign up"
  end
end
