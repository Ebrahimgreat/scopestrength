defmodule Scopestrength.TrainingTest do
  use Scopestrength.DataCase, async: true

  import Scopestrength.ExercisesFixtures
  import Scopestrength.PeopleFixtures
  import Scopestrength.TrainingFixtures

  alias Scopestrength.Training
  alias Scopestrength.Training.{Workout, WorkoutDetails}

  describe "workouts" do
    test "require a client" do
      {:error, changeset} = Training.create_workout(%{name: "x"})
      assert %{client_id: ["can't be blank"]} = errors_on(changeset)
    end

    test "get a date when saved without one" do
      client = client_fixture()
      {:ok, workout} = Training.create_workout(%{name: "Untitled", client_id: client.id})
      assert %DateTime{} = workout.date
    end

    test "keep an explicit date" do
      date = ~U[2026-01-02 10:00:00Z]
      workout = workout_fixture(%{date: date})
      assert workout.date == date
    end

    test "update and delete cascade to sets" do
      workout = workout_fixture()
      details = workout_details_fixture(%{workout_id: workout.id})

      {:ok, workout} = Training.update_workout(workout, %{name: "Leg day", notes: "Easy"})
      assert Training.get_workout!(workout.id).name == "Leg day"

      {:ok, _} = Training.delete_workout(workout)
      assert_raise Ecto.NoResultsError, fn -> Training.get_workout!(workout.id) end
      assert_raise Ecto.NoResultsError, fn -> Training.get_workout_details!(details.id) end
    end

    test "list_workouts/0 and change_workout/1" do
      workout = workout_fixture()
      assert workout.id in Enum.map(Training.list_workouts(), & &1.id)
      assert %Ecto.Changeset{} = Training.change_workout(%Workout{})
    end
  end

  describe "workout details" do
    test "validate side and RPE range" do
      workout = workout_fixture()
      exercise = exercise_fixture()

      {:error, changeset} =
        Training.create_workout_details(%{workout_id: workout.id, exercise_id: exercise.id, set: 1, side: "up"})

      assert "is invalid" in errors_on(changeset).side

      {:error, changeset} =
        Training.create_workout_details(%{workout_id: workout.id, exercise_id: exercise.id, set: 1, rpe: 11})

      assert errors_on(changeset).rpe != []
    end

    test "default side is both and progression status is hold" do
      details = workout_details_fixture()
      assert details.side == "both"
      assert details.progression_status == "hold"
    end

    test "update and delete" do
      details = workout_details_fixture()
      {:ok, details} = Training.update_workout_details(details, %{reps: 12, weight: 60, rpe: 8})
      assert %WorkoutDetails{reps: 12.0, weight: 60.0, rpe: 8.0} = Training.get_workout_details!(details.id)
      {:ok, _} = Training.delete_workout_details(details)
      assert_raise Ecto.NoResultsError, fn -> Training.get_workout_details!(details.id) end
    end
  end

  describe "progress_summary/1" do
    test "is empty for a client without workouts" do
      client = client_fixture()
      assert {:ok, %{total_workouts: 0, total_sets: 0, last_workout_at: nil, pr: nil}} = Training.progress_summary(client.id)
    end

    test "counts workouts and sets and finds the heaviest set" do
      client = client_fixture()
      exercise = exercise_fixture(%{name: "Deadlift"})
      workout = workout_fixture(%{client_id: client.id, date: ~U[2026-03-01 09:00:00Z]})
      workout_details_fixture(%{workout_id: workout.id, exercise_id: exercise.id, set: 1, weight: 100.0, reps: 5.0})
      workout_details_fixture(%{workout_id: workout.id, exercise_id: exercise.id, set: 2, weight: 120.0, reps: 3.0})
      _other = workout_fixture(%{client_id: client.id, date: ~U[2026-03-05 09:00:00Z]})

      {:ok, summary} = Training.progress_summary(client.id)
      assert summary.total_workouts == 2
      assert summary.total_sets == 2
      assert summary.last_workout_at == ~U[2026-03-05 09:00:00Z]
      assert %{weight: 120.0, reps: 3.0, exercise_name: "Deadlift"} = summary.pr
    end
  end
end
