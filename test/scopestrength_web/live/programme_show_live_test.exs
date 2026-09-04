defmodule ScopestrengthWeb.ProgrammeShowLiveTest do
  use ScopestrengthWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Scopestrength.PeopleFixtures
  import Scopestrength.ProgrammesFixtures

  alias Scopestrength.{ClientProgressions, Programmes, Repo}
  alias Scopestrength.Notifications.Notification

  setup :log_in_trainer

  test "assigning a client seeds progression and notifies them", %{conn: conn, trainer: trainer, user: user} do
    client = client_fixture(%{trainer: trainer})
    %{programme: programme, exercise: exercise} = full_programme_fixture(%{user_id: user.id})

    {:ok, view, _html} = live(conn, ~p"/trainer/programmes/#{programme.id}")
    html = render_click(view, "assignClient", %{"client_id" => to_string(client.id)})

    assert html =~ "2 progressions seeded"
    assert MapSet.to_list(Programmes.assigned_client_ids(programme.id)) == [client.id]
    assert length(ClientProgressions.list_for_exercise(client.id, exercise.id)) == 2

    [notification] = Repo.all(Notification)
    assert notification.type == "programme_assigned"
    assert notification.recipient_type == "client"
    assert notification.recipient_id == client.id
    assert notification.data["programme_id"] == programme.id
    assert notification.data["programme_name"] == programme.name
  end

  test "removing a client notifies them", %{conn: conn, trainer: trainer, user: user} do
    client = client_fixture(%{trainer: trainer})
    %{programme: programme} = full_programme_fixture(%{user_id: user.id})
    {:ok, _} = Programmes.assign_client_to_programme(programme.id, client.id)

    {:ok, view, _html} = live(conn, ~p"/trainer/programmes/#{programme.id}")
    render_click(view, "unassignClient", %{"client_id" => to_string(client.id), "name" => "Client"})
    html = render_click(view, "confirm_unassign", %{})

    assert html =~ "Client removed from programme"
    assert MapSet.to_list(Programmes.assigned_client_ids(programme.id)) == []
    assert [%Notification{type: "programme_unenrolled"}] = Repo.all(Notification)
  end

  test "another trainer's programme is not shown", %{conn: conn} do
    programme = programme_fixture()
    assert {:error, {:redirect, %{to: "/programmes"}}} = live(conn, ~p"/trainer/programmes/#{programme.id}")
  end

  test "deleting a template works with the integer id the dialog sends", %{conn: conn, user: user} do
    %{programme: programme, template: template} = full_programme_fixture(%{user_id: user.id})
    {:ok, view, _html} = live(conn, ~p"/trainer/programmes/#{programme.id}")
    render_click(view, "deleteTemplate", %{"id" => template.id})
    assert_raise Ecto.NoResultsError, fn -> Programmes.get_programme_template!(template.id) end
  end
end
