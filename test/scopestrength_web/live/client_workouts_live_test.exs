defmodule ScopestrengthWeb.ClientWorkoutsLiveTest do
  use ScopestrengthWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Scopestrength.ExercisesFixtures
  import Scopestrength.TrainingFixtures

  alias Scopestrength.{Notifications, Repo, Training}
  alias Scopestrength.Training.Workout

  setup :log_in_client

  test "creating a workout notifies the trainer", %{conn: conn, client: client, trainer: trainer} do
    {:ok, view, _html} = live(conn, ~p"/client/workouts")
    render_click(view, "createWorkout", %{})

    assert [%Workout{name: "Untitled"}] = Repo.all(Workout)

    [notification] = Repo.all(Scopestrength.Notifications.Notification)
    assert notification.recipient_type == "trainer"
    assert notification.recipient_id == trainer.id
    assert notification.type == "workout_created"
    assert notification.data["client_id"] == client.id
    assert Notifications.get_notification!(notification.id)
  end

  test "deleting a workout works with the integer id the confirm dialog sends", %{conn: conn, client: client} do
    workout = workout_fixture(%{client_id: client.id})
    {:ok, view, _html} = live(conn, ~p"/client/workouts")

    html = render_click(view, "deleteWorkout", %{"id" => workout.id})
    refute html =~ workout.name
    assert_raise Ecto.NoResultsError, fn -> Training.get_workout!(workout.id) end
  end

  test "the workout page adds, edits and removes sets", %{conn: conn, client: client} do
    workout = workout_fixture(%{client_id: client.id})
    exercise = exercise_fixture(%{name: "Squat"})
    {:ok, view, _html} = live(conn, ~p"/client/workouts/#{workout.id}")

    html = render_click(view, "addExercise", %{"id" => to_string(exercise.id)})
    assert html =~ "Squat"
    [detail] = Repo.all(Scopestrength.Training.WorkoutDetails)
    assert detail.set == 1

    render_change(view, "updateExercise", %{
      "workout_details" => %{"id" => to_string(detail.id), "reps" => "8", "weight" => "100", "rir" => "1", "rpe" => "9"}
    })

    render_click(view, "save_all_changes", %{})
    saved = Training.get_workout_details!(detail.id)
    assert saved.reps == 8.0
    assert saved.weight == 100.0
    assert saved.rpe == 9.0

    render_click(view, "deleteExercise", %{"id" => detail.id})
    assert Repo.all(Scopestrength.Training.WorkoutDetails) == []
  end

  test "renaming a workout without a date keeps the existing date", %{conn: conn, client: client} do
    workout = workout_fixture(%{client_id: client.id, date: ~U[2026-04-01 08:00:00Z]})
    {:ok, view, _html} = live(conn, ~p"/client/workouts/#{workout.id}")

    render_click(view, "toggle_edit_mode", %{})
    render_submit(view, "update_workout", %{"workout" => %{"name" => "Renamed", "date" => ""}})

    updated = Training.get_workout!(workout.id)
    assert updated.name == "Renamed"
    assert updated.date == ~U[2026-04-01 08:00:00Z]
  end
end
