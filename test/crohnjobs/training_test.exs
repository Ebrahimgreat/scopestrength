defmodule Crohnjobs.TrainingTest do
  use Crohnjobs.DataCase

  alias Crohnjobs.Training

  describe "workouts" do
    alias Crohnjobs.Training.Workout

    import Crohnjobs.TrainingFixtures

    @invalid_attrs %{}

    test "list_workouts/0 returns all workouts" do
      workout = workout_fixture()
      assert Training.list_workouts() == [workout]
    end

    test "get_workout!/1 returns the workout with given id" do
      workout = workout_fixture()
      assert Training.get_workout!(workout.id) == workout
    end

    test "create_workout/1 with valid data creates a workout" do
      valid_attrs = %{}

      assert {:ok, %Workout{} = workout} = Training.create_workout(valid_attrs)
    end

    test "create_workout/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Training.create_workout(@invalid_attrs)
    end

    test "update_workout/2 with valid data updates the workout" do
      workout = workout_fixture()
      update_attrs = %{}

      assert {:ok, %Workout{} = workout} = Training.update_workout(workout, update_attrs)
    end

    test "update_workout/2 with invalid data returns error changeset" do
      workout = workout_fixture()
      assert {:error, %Ecto.Changeset{}} = Training.update_workout(workout, @invalid_attrs)
      assert workout == Training.get_workout!(workout.id)
    end

    test "delete_workout/1 deletes the workout" do
      workout = workout_fixture()
      assert {:ok, %Workout{}} = Training.delete_workout(workout)
      assert_raise Ecto.NoResultsError, fn -> Training.get_workout!(workout.id) end
    end

    test "change_workout/1 returns a workout changeset" do
      workout = workout_fixture()
      assert %Ecto.Changeset{} = Training.change_workout(workout)
    end
  end

  describe "workout_details" do
    alias Crohnjobs.Training.WorkoutDetails

    import Crohnjobs.TrainingFixtures

    @invalid_attrs %{}

    test "list_workout_details/0 returns all workout_details" do
      workout_details = workout_details_fixture()
      assert Training.list_workout_details() == [workout_details]
    end

    test "get_workout_details!/1 returns the workout_details with given id" do
      workout_details = workout_details_fixture()
      assert Training.get_workout_details!(workout_details.id) == workout_details
    end

    test "create_workout_details/1 with valid data creates a workout_details" do
      valid_attrs = %{}

      assert {:ok, %WorkoutDetails{} = workout_details} =
               Training.create_workout_details(valid_attrs)
    end

    test "create_workout_details/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Training.create_workout_details(@invalid_attrs)
    end

    test "update_workout_details/2 with valid data updates the workout_details" do
      workout_details = workout_details_fixture()
      update_attrs = %{}

      assert {:ok, %WorkoutDetails{} = workout_details} =
               Training.update_workout_details(workout_details, update_attrs)
    end

    test "update_workout_details/2 with invalid data returns error changeset" do
      workout_details = workout_details_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Training.update_workout_details(workout_details, @invalid_attrs)

      assert workout_details == Training.get_workout_details!(workout_details.id)
    end

    test "delete_workout_details/1 deletes the workout_details" do
      workout_details = workout_details_fixture()
      assert {:ok, %WorkoutDetails{}} = Training.delete_workout_details(workout_details)

      assert_raise Ecto.NoResultsError, fn ->
        Training.get_workout_details!(workout_details.id)
      end
    end

    test "change_workout_details/1 returns a workout_details changeset" do
      workout_details = workout_details_fixture()
      assert %Ecto.Changeset{} = Training.change_workout_details(workout_details)
    end
  end

  describe "set_types" do
    alias Crohnjobs.Training.SetType

    import Crohnjobs.TrainingFixtures

    @invalid_attrs %{name: nil, description: nil}

    test "list_set_types/0 returns all set_types" do
      set_type = set_type_fixture()
      assert Training.list_set_types() == [set_type]
    end

    test "get_set_type!/1 returns the set_type with given id" do
      set_type = set_type_fixture()
      assert Training.get_set_type!(set_type.id) == set_type
    end

    test "create_set_type/1 with valid data creates a set_type" do
      valid_attrs = %{name: "some name", description: "some description"}

      assert {:ok, %SetType{} = set_type} = Training.create_set_type(valid_attrs)
      assert set_type.name == "some name"
      assert set_type.description == "some description"
    end

    test "create_set_type/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Training.create_set_type(@invalid_attrs)
    end

    test "update_set_type/2 with valid data updates the set_type" do
      set_type = set_type_fixture()
      update_attrs = %{name: "some updated name", description: "some updated description"}

      assert {:ok, %SetType{} = set_type} = Training.update_set_type(set_type, update_attrs)
      assert set_type.name == "some updated name"
      assert set_type.description == "some updated description"
    end

    test "update_set_type/2 with invalid data returns error changeset" do
      set_type = set_type_fixture()
      assert {:error, %Ecto.Changeset{}} = Training.update_set_type(set_type, @invalid_attrs)
      assert set_type == Training.get_set_type!(set_type.id)
    end

    test "delete_set_type/1 deletes the set_type" do
      set_type = set_type_fixture()
      assert {:ok, %SetType{}} = Training.delete_set_type(set_type)
      assert_raise Ecto.NoResultsError, fn -> Training.get_set_type!(set_type.id) end
    end

    test "change_set_type/1 returns a set_type changeset" do
      set_type = set_type_fixture()
      assert %Ecto.Changeset{} = Training.change_set_type(set_type)
    end
  end
end
