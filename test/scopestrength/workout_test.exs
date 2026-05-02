defmodule Scopestrength.WorkoutTest do
  use Scopestrength.DataCase

  alias Scopestrength.Workout

  describe "exercises" do
    alias Scopestrength.Workout.Exercise

    import Scopestrength.WorkoutFixtures

    @invalid_attrs %{name: nil, type: nil, equipment: nil}

    test "list_exercises/0 returns all exercises" do
      exercise = exercise_fixture()
      assert Workout.list_exercises() == [exercise]
    end

    test "get_exercise!/1 returns the exercise with given id" do
      exercise = exercise_fixture()
      assert Workout.get_exercise!(exercise.id) == exercise
    end

    test "create_exercise/1 with valid data creates a exercise" do
      valid_attrs = %{name: "some name", type: "some type", equipment: "some equipment"}

      assert {:ok, %Exercise{} = exercise} = Workout.create_exercise(valid_attrs)
      assert exercise.name == "some name"
      assert exercise.type == "some type"
      assert exercise.equipment == "some equipment"
    end

    test "create_exercise/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Workout.create_exercise(@invalid_attrs)
    end

    test "update_exercise/2 with valid data updates the exercise" do
      exercise = exercise_fixture()
      update_attrs = %{name: "some updated name", type: "some updated type", equipment: "some updated equipment"}

      assert {:ok, %Exercise{} = exercise} = Workout.update_exercise(exercise, update_attrs)
      assert exercise.name == "some updated name"
      assert exercise.type == "some updated type"
      assert exercise.equipment == "some updated equipment"
    end

    test "update_exercise/2 with invalid data returns error changeset" do
      exercise = exercise_fixture()
      assert {:error, %Ecto.Changeset{}} = Workout.update_exercise(exercise, @invalid_attrs)
      assert exercise == Workout.get_exercise!(exercise.id)
    end

    test "delete_exercise/1 deletes the exercise" do
      exercise = exercise_fixture()
      assert {:ok, %Exercise{}} = Workout.delete_exercise(exercise)
      assert_raise Ecto.NoResultsError, fn -> Workout.get_exercise!(exercise.id) end
    end

    test "change_exercise/1 returns a exercise changeset" do
      exercise = exercise_fixture()
      assert %Ecto.Changeset{} = Workout.change_exercise(exercise)
    end
  end
end
