defmodule Crohnjobs.FitnessTest do
  use Crohnjobs.DataCase

  alias Crohnjobs.Fitness

  describe "workouts" do
    alias Crohnjobs.Fitness.Workout

    import Crohnjobs.FitnessFixtures

    @invalid_attrs %{}

    test "list_workouts/0 returns all workouts" do
      workout = workout_fixture()
      assert Fitness.list_workouts() == [workout]
    end

    test "get_workout!/1 returns the workout with given id" do
      workout = workout_fixture()
      assert Fitness.get_workout!(workout.id) == workout
    end

    test "create_workout/1 with valid data creates a workout" do
      valid_attrs = %{}

      assert {:ok, %Workout{} = workout} = Fitness.create_workout(valid_attrs)
    end

    test "create_workout/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Fitness.create_workout(@invalid_attrs)
    end

    test "update_workout/2 with valid data updates the workout" do
      workout = workout_fixture()
      update_attrs = %{}

      assert {:ok, %Workout{} = workout} = Fitness.update_workout(workout, update_attrs)
    end

    test "update_workout/2 with invalid data returns error changeset" do
      workout = workout_fixture()
      assert {:error, %Ecto.Changeset{}} = Fitness.update_workout(workout, @invalid_attrs)
      assert workout == Fitness.get_workout!(workout.id)
    end

    test "delete_workout/1 deletes the workout" do
      workout = workout_fixture()
      assert {:ok, %Workout{}} = Fitness.delete_workout(workout)
      assert_raise Ecto.NoResultsError, fn -> Fitness.get_workout!(workout.id) end
    end

    test "change_workout/1 returns a workout changeset" do
      workout = workout_fixture()
      assert %Ecto.Changeset{} = Fitness.change_workout(workout)
    end
  end

  describe "workout_details" do
    alias Crohnjobs.Fitness.WorkoutDetail

    import Crohnjobs.FitnessFixtures

    @invalid_attrs %{}

    test "list_workout_details/0 returns all workout_details" do
      workout_detail = workout_detail_fixture()
      assert Fitness.list_workout_details() == [workout_detail]
    end

    test "get_workout_detail!/1 returns the workout_detail with given id" do
      workout_detail = workout_detail_fixture()
      assert Fitness.get_workout_detail!(workout_detail.id) == workout_detail
    end

    test "create_workout_detail/1 with valid data creates a workout_detail" do
      valid_attrs = %{}

      assert {:ok, %WorkoutDetail{} = workout_detail} = Fitness.create_workout_detail(valid_attrs)
    end

    test "create_workout_detail/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Fitness.create_workout_detail(@invalid_attrs)
    end

    test "update_workout_detail/2 with valid data updates the workout_detail" do
      workout_detail = workout_detail_fixture()
      update_attrs = %{}

      assert {:ok, %WorkoutDetail{} = workout_detail} = Fitness.update_workout_detail(workout_detail, update_attrs)
    end

    test "update_workout_detail/2 with invalid data returns error changeset" do
      workout_detail = workout_detail_fixture()
      assert {:error, %Ecto.Changeset{}} = Fitness.update_workout_detail(workout_detail, @invalid_attrs)
      assert workout_detail == Fitness.get_workout_detail!(workout_detail.id)
    end

    test "delete_workout_detail/1 deletes the workout_detail" do
      workout_detail = workout_detail_fixture()
      assert {:ok, %WorkoutDetail{}} = Fitness.delete_workout_detail(workout_detail)
      assert_raise Ecto.NoResultsError, fn -> Fitness.get_workout_detail!(workout_detail.id) end
    end

    test "change_workout_detail/1 returns a workout_detail changeset" do
      workout_detail = workout_detail_fixture()
      assert %Ecto.Changeset{} = Fitness.change_workout_detail(workout_detail)
    end
  end
end
