defmodule ScopestrengthWeb.DeleteOwnershipTest do
  use ScopestrengthWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Scopestrength.AccountFixtures
  import Scopestrength.ExercisesFixtures
  import Scopestrength.PeopleFixtures
  import Scopestrength.ProgrammesFixtures
  import Scopestrength.RecordsFixtures
  import Scopestrength.TrainingFixtures

  alias Scopestrength.{ClientNote, ClientWeight, Exercises, Notifications, Programmes, Repo, Training}

  describe "client weight" do
    setup :log_in_client

    test "a client cannot delete another client's weight entry", %{conn: conn, client: client} do
      other = client_fixture()
      weight = client_weight_fixture(%{client_id: other.id})

      {:ok, view, _html} = live(conn, ~p"/client/weight")
      render_click(view, "delete_weight", %{"id" => weight.id})

      assert Repo.get(ClientWeight.ClientWeights, weight.id)
      refute weight.client_id == client.id
    end
  end

  describe "client workouts" do
    setup :log_in_client

    test "a client cannot delete another client's workout", %{conn: conn} do
      other_workout = workout_fixture()

      {:ok, view, _html} = live(conn, ~p"/client/workouts")
      render_click(view, "deleteWorkout", %{"id" => other_workout.id})

      assert Repo.get(Training.Workout, other_workout.id)
    end
  end

  describe "client workout show" do
    setup :log_in_client

    test "a client cannot delete a set from another client's workout", %{conn: conn, client: client} do
      own_workout = workout_fixture(%{client_id: client.id})
      other_detail = workout_details_fixture()

      {:ok, view, _html} = live(conn, ~p"/client/workouts/#{own_workout.id}")
      render_click(view, "deleteExercise", %{"id" => other_detail.id})

      assert Repo.get(Training.WorkoutDetails, other_detail.id)
    end
  end

  describe "client programme show" do
    setup :log_in_client

    test "a client cannot delete another user's programme template", %{conn: conn, user: user} do
      mine = full_programme_fixture(%{user_id: user.id})
      other = full_programme_fixture()

      {:ok, view, _html} = live(conn, ~p"/client/programmes/#{mine.programme.id}")
      render_click(view, "deleteTemplate", %{"id" => other.template.id})

      assert Repo.get(Programmes.ProgrammeTemplate, other.template.id)
    end
  end

  describe "trainer client notes" do
    setup :log_in_trainer

    test "a trainer cannot delete another client's note", %{conn: conn, trainer: trainer} do
      mine = client_fixture(%{trainer: trainer})
      other_note = client_note_fixture()

      {:ok, view, _html} = live(conn, ~p"/trainer/clients/#{mine.id}/notes")
      render_click(view, "deleteNote", %{"id" => other_note.id})

      assert Repo.get(ClientNote.ClientNotes, other_note.id)
    end
  end

  describe "trainer exercises" do
    setup :log_in_trainer

    test "a trainer cannot delete a shared library exercise", %{conn: conn} do
      shared = exercise_fixture(%{is_custom: false})

      {:ok, view, _html} = live(conn, ~p"/trainer/exercises")
      render_click(view, "deleteExercise", %{"id" => shared.id})

      assert Repo.get(Exercises.Exercise, shared.id)
    end

    test "a trainer cannot delete another trainer's custom exercise", %{conn: conn} do
      other_user = trainer_user_fixture()
      other_custom = exercise_fixture(%{is_custom: true, user_id: other_user.id})

      {:ok, view, _html} = live(conn, ~p"/trainer/exercises")
      render_click(view, "deleteExercise", %{"id" => other_custom.id})

      assert Repo.get(Exercises.Exercise, other_custom.id)
    end

    test "a trainer can delete their own custom exercise", %{conn: conn, user: user} do
      mine = exercise_fixture(%{is_custom: true, user_id: user.id})

      {:ok, view, _html} = live(conn, ~p"/trainer/exercises")
      render_click(view, "deleteExercise", %{"id" => mine.id})

      refute Repo.get(Exercises.Exercise, mine.id)
    end
  end

  describe "trainer notifications" do
    setup :log_in_trainer

    test "a trainer cannot delete another trainer's notification", %{conn: conn} do
      other_notification = notification_fixture(%{recipient_id: 999_999, recipient_type: "trainer"})

      {:ok, view, _html} = live(conn, ~p"/trainer/notifications")
      render_click(view, "delete_notification", %{"id" => to_string(other_notification.id)})

      assert Repo.get(Notifications.Notification, other_notification.id)
    end
  end

  describe "trainer programme show" do
    setup :log_in_trainer

    test "a trainer cannot delete another user's programme template", %{conn: conn, user: user} do
      mine = full_programme_fixture(%{user_id: user.id})
      other = full_programme_fixture()

      {:ok, view, _html} = live(conn, ~p"/trainer/programmes/#{mine.programme.id}")
      render_click(view, "deleteTemplate", %{"id" => other.template.id})

      assert Repo.get(Programmes.ProgrammeTemplate, other.template.id)
    end
  end
end
