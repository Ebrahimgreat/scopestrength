defmodule ScopestrengthWeb.UserSessionControllerTest do
  use ScopestrengthWeb.ConnCase, async: true

  import Scopestrength.AccountFixtures
  import Scopestrength.PeopleFixtures

  test "logging in with the right password lands on the role dashboard", %{conn: conn} do
    trainer = trainer_fixture()

    conn =
      post(conn, ~p"/users/log_in", %{
        "user" => %{"email" => trainer.user.email, "password" => valid_user_password()}
      })

    assert get_session(conn, :user_token)
    assert redirected_to(conn) == ~p"/trainer"
  end

  test "a client lands on the client dashboard", %{conn: conn} do
    client = client_fixture()

    conn =
      post(conn, ~p"/users/log_in", %{
        "user" => %{"email" => client.user.email, "password" => valid_user_password()}
      })

    assert redirected_to(conn) == ~p"/client"
  end

  test "a wrong password is rejected", %{conn: conn} do
    user = user_fixture()

    conn =
      post(conn, ~p"/users/log_in", %{"user" => %{"email" => user.email, "password" => "wrong password!!"}})

    refute get_session(conn, :user_token)
    assert redirected_to(conn) == ~p"/users/log_in"
  end

  test "logging out clears the session", %{conn: conn} do
    conn = conn |> log_in_user(user_fixture()) |> delete(~p"/users/log_out")
    refute get_session(conn, :user_token)
    assert redirected_to(conn) == ~p"/users/log_in"
  end

  test "protected pages redirect anonymous visitors", %{conn: conn} do
    conn = get(conn, ~p"/trainer")
    assert redirected_to(conn) == ~p"/users/log_in"
  end
end
