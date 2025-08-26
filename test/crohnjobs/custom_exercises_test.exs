defmodule Crohnjobs.CustomExercisesTest do
  use Crohnjobs.DataCase

  alias Crohnjobs.CustomExercises

  describe "custom_exercises" do
    alias Crohnjobs.CustomExercises.CustomExercise

    import Crohnjobs.CustomExercisesFixtures

    @invalid_attrs %{}

    test "list_custom_exercises/0 returns all custom_exercises" do
      custom_exercise = custom_exercise_fixture()
      assert CustomExercises.list_custom_exercises() == [custom_exercise]
    end

    test "get_custom_exercise!/1 returns the custom_exercise with given id" do
      custom_exercise = custom_exercise_fixture()
      assert CustomExercises.get_custom_exercise!(custom_exercise.id) == custom_exercise
    end

    test "create_custom_exercise/1 with valid data creates a custom_exercise" do
      valid_attrs = %{}

      assert {:ok, %CustomExercise{} = custom_exercise} = CustomExercises.create_custom_exercise(valid_attrs)
    end

    test "create_custom_exercise/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = CustomExercises.create_custom_exercise(@invalid_attrs)
    end

    test "update_custom_exercise/2 with valid data updates the custom_exercise" do
      custom_exercise = custom_exercise_fixture()
      update_attrs = %{}

      assert {:ok, %CustomExercise{} = custom_exercise} = CustomExercises.update_custom_exercise(custom_exercise, update_attrs)
    end

    test "update_custom_exercise/2 with invalid data returns error changeset" do
      custom_exercise = custom_exercise_fixture()
      assert {:error, %Ecto.Changeset{}} = CustomExercises.update_custom_exercise(custom_exercise, @invalid_attrs)
      assert custom_exercise == CustomExercises.get_custom_exercise!(custom_exercise.id)
    end

    test "delete_custom_exercise/1 deletes the custom_exercise" do
      custom_exercise = custom_exercise_fixture()
      assert {:ok, %CustomExercise{}} = CustomExercises.delete_custom_exercise(custom_exercise)
      assert_raise Ecto.NoResultsError, fn -> CustomExercises.get_custom_exercise!(custom_exercise.id) end
    end

    test "change_custom_exercise/1 returns a custom_exercise changeset" do
      custom_exercise = custom_exercise_fixture()
      assert %Ecto.Changeset{} = CustomExercises.change_custom_exercise(custom_exercise)
    end
  end
end
