defmodule ScopestrengthWeb.NotificationsLiveTest do
  use ScopestrengthWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Scopestrength.PeopleFixtures
  import Scopestrength.ProgrammesFixtures
  import Scopestrength.RecordsFixtures
  import Scopestrength.TrainingFixtures

  alias Scopestrength.Notifications

  describe "trainer" do
    setup :log_in_trainer

    test "opening a notification for a deleted workout explains instead of crashing", %{conn: conn, trainer: trainer} do
      client = client_fixture(%{trainer: trainer})

      notification =
        notification_fixture(%{
          recipient_id: trainer.id,
          recipient_type: "trainer",
          type: "workout_created",
          data: %{workout_id: 999_999, client_id: client.id}
        })

      {:ok, view, _html} = live(conn, ~p"/trainer/notifications")
      html = render_click(view, "open", %{"id" => to_string(notification.id)})

      assert html =~ "This workout no longer exists"
      assert Notifications.get_notification!(notification.id).read_at
    end

    test "opening a notification for an existing workout navigates to it", %{conn: conn, trainer: trainer} do
      client = client_fixture(%{trainer: trainer})
      workout = workout_fixture(%{client_id: client.id})

      notification =
        notification_fixture(%{
          recipient_id: trainer.id,
          recipient_type: "trainer",
          type: "workout_created",
          data: %{workout_id: workout.id, client_id: client.id}
        })

      {:ok, view, _html} = live(conn, ~p"/trainer/notifications")
      render_click(view, "open", %{"id" => to_string(notification.id)})
      assert_redirect(view, ~p"/trainer/clients/#{client.id}/workouts/#{workout.id}")
    end

    test "a deleted programme is reported", %{conn: conn, trainer: trainer} do
      notification =
        notification_fixture(%{recipient_id: trainer.id, recipient_type: "trainer", type: "programme_assigned", data: %{programme_id: 999_999}})

      {:ok, view, _html} = live(conn, ~p"/trainer/notifications")
      assert render_click(view, "open", %{"id" => to_string(notification.id)}) =~ "This programme no longer exists"
    end

    test "mark all read and delete", %{conn: conn, trainer: trainer} do
      n1 = notification_fixture(%{recipient_id: trainer.id, recipient_type: "trainer"})
      n2 = notification_fixture(%{recipient_id: trainer.id, recipient_type: "trainer"})

      {:ok, view, _html} = live(conn, ~p"/trainer/notifications")
      render_click(view, "mark_all_read", %{})
      assert Notifications.get_notification!(n1.id).read_at
      assert Notifications.get_notification!(n2.id).read_at

      render_click(view, "delete_notification", %{"id" => to_string(n1.id)})
      assert_raise Ecto.NoResultsError, fn -> Notifications.get_notification!(n1.id) end
    end
  end

  describe "client" do
    setup :log_in_client

    test "an assigned programme opens the programmes page", %{conn: conn, client: client} do
      %{programme: programme} = full_programme_fixture()

      notification =
        notification_fixture(%{
          recipient_id: client.id,
          recipient_type: "client",
          actor_type: "trainer",
          type: "programme_assigned",
          data: %{programme_id: programme.id, programme_name: programme.name}
        })

      {:ok, view, html} = live(conn, ~p"/client/notifications")
      assert html =~ "You were assigned #{programme.name}"

      render_click(view, "open", %{"id" => to_string(notification.id)})
      assert_redirect(view, ~p"/client/programmes")
    end

    test "a deleted programme is reported", %{conn: conn, client: client} do
      notification =
        notification_fixture(%{recipient_id: client.id, recipient_type: "client", actor_type: "trainer", type: "programme_assigned", data: %{programme_id: 999_999}})

      {:ok, view, _html} = live(conn, ~p"/client/notifications")
      assert render_click(view, "open", %{"id" => to_string(notification.id)}) =~ "This programme no longer exists"
    end
  end
end
