defmodule ScopestrengthWeb.WorkoutsLiveTest do
  use ScopestrengthWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Scopestrength.PeopleFixtures

  setup :log_in_trainer

  test "shows a trainer their own client's workouts", %{conn: conn, trainer: trainer} do
    client = client_fixture(%{trainer: trainer})
    {:ok, _view, html} = live(conn, ~p"/trainer/clients/#{client.id}/workouts")
    assert html =~ client.user.name
  end

  test "redirects instead of crashing for a nonexistent client", %{conn: conn} do
    assert {:error, {:redirect, %{to: "/trainer/clients", flash: %{"error" => message}}}} =
             live(conn, ~p"/trainer/clients/999999/workouts")

    assert message =~ "not found"
  end

  test "redirects instead of crashing for another trainer's client", %{conn: conn} do
    other_client = client_fixture()

    assert {:error, {:redirect, %{to: "/trainer/clients", flash: %{"error" => message}}}} =
             live(conn, ~p"/trainer/clients/#{other_client.id}/workouts")

    assert message =~ "not found"
  end
end
