defmodule Crohnjobs.ExercisesTest do
  use Crohnjobs.DataCase

  alias Crohnjobs.Exercises

  describe "mucles" do
    alias Crohnjobs.Exercises.Muscles

    import Crohnjobs.ExercisesFixtures

    @invalid_attrs %{name: nil}

    test "list_mucles/0 returns all mucles" do
      muscles = muscles_fixture()
      assert Exercises.list_mucles() == [muscles]
    end

    test "get_muscles!/1 returns the muscles with given id" do
      muscles = muscles_fixture()
      assert Exercises.get_muscles!(muscles.id) == muscles
    end

    test "create_muscles/1 with valid data creates a muscles" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Muscles{} = muscles} = Exercises.create_muscles(valid_attrs)
      assert muscles.name == "some name"
    end

    test "create_muscles/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Exercises.create_muscles(@invalid_attrs)
    end

    test "update_muscles/2 with valid data updates the muscles" do
      muscles = muscles_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Muscles{} = muscles} = Exercises.update_muscles(muscles, update_attrs)
      assert muscles.name == "some updated name"
    end

    test "update_muscles/2 with invalid data returns error changeset" do
      muscles = muscles_fixture()
      assert {:error, %Ecto.Changeset{}} = Exercises.update_muscles(muscles, @invalid_attrs)
      assert muscles == Exercises.get_muscles!(muscles.id)
    end

    test "delete_muscles/1 deletes the muscles" do
      muscles = muscles_fixture()
      assert {:ok, %Muscles{}} = Exercises.delete_muscles(muscles)
      assert_raise Ecto.NoResultsError, fn -> Exercises.get_muscles!(muscles.id) end
    end

    test "change_muscles/1 returns a muscles changeset" do
      muscles = muscles_fixture()
      assert %Ecto.Changeset{} = Exercises.change_muscles(muscles)
    end
  end

  describe "equipment" do
    alias Crohnjobs.Exercises.Equipment

    import Crohnjobs.ExercisesFixtures

    @invalid_attrs %{name: nil}

    test "list_equipment/0 returns all equipment" do
      equipment = equipment_fixture()
      assert Exercises.list_equipment() == [equipment]
    end

    test "get_equipment!/1 returns the equipment with given id" do
      equipment = equipment_fixture()
      assert Exercises.get_equipment!(equipment.id) == equipment
    end

    test "create_equipment/1 with valid data creates a equipment" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Equipment{} = equipment} = Exercises.create_equipment(valid_attrs)
      assert equipment.name == "some name"
    end

    test "create_equipment/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Exercises.create_equipment(@invalid_attrs)
    end

    test "update_equipment/2 with valid data updates the equipment" do
      equipment = equipment_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Equipment{} = equipment} = Exercises.update_equipment(equipment, update_attrs)
      assert equipment.name == "some updated name"
    end

    test "update_equipment/2 with invalid data returns error changeset" do
      equipment = equipment_fixture()
      assert {:error, %Ecto.Changeset{}} = Exercises.update_equipment(equipment, @invalid_attrs)
      assert equipment == Exercises.get_equipment!(equipment.id)
    end

    test "delete_equipment/1 deletes the equipment" do
      equipment = equipment_fixture()
      assert {:ok, %Equipment{}} = Exercises.delete_equipment(equipment)
      assert_raise Ecto.NoResultsError, fn -> Exercises.get_equipment!(equipment.id) end
    end

    test "change_equipment/1 returns a equipment changeset" do
      equipment = equipment_fixture()
      assert %Ecto.Changeset{} = Exercises.change_equipment(equipment)
    end
  end

  describe "exercise_muscle_contribution" do
    alias Crohnjobs.Exercises.ExerciseMuscleContribution

    import Crohnjobs.ExercisesFixtures

    @invalid_attrs %{}

    test "list_exercise_muscle_contribution/0 returns all exercise_muscle_contribution" do
      exercise_muscle_contribution = exercise_muscle_contribution_fixture()
      assert Exercises.list_exercise_muscle_contribution() == [exercise_muscle_contribution]
    end

    test "get_exercise_muscle_contribution!/1 returns the exercise_muscle_contribution with given id" do
      exercise_muscle_contribution = exercise_muscle_contribution_fixture()
      assert Exercises.get_exercise_muscle_contribution!(exercise_muscle_contribution.id) == exercise_muscle_contribution
    end

    test "create_exercise_muscle_contribution/1 with valid data creates a exercise_muscle_contribution" do
      valid_attrs = %{}

      assert {:ok, %ExerciseMuscleContribution{} = exercise_muscle_contribution} = Exercises.create_exercise_muscle_contribution(valid_attrs)
    end

    test "create_exercise_muscle_contribution/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Exercises.create_exercise_muscle_contribution(@invalid_attrs)
    end

    test "update_exercise_muscle_contribution/2 with valid data updates the exercise_muscle_contribution" do
      exercise_muscle_contribution = exercise_muscle_contribution_fixture()
      update_attrs = %{}

      assert {:ok, %ExerciseMuscleContribution{} = exercise_muscle_contribution} = Exercises.update_exercise_muscle_contribution(exercise_muscle_contribution, update_attrs)
    end

    test "update_exercise_muscle_contribution/2 with invalid data returns error changeset" do
      exercise_muscle_contribution = exercise_muscle_contribution_fixture()
      assert {:error, %Ecto.Changeset{}} = Exercises.update_exercise_muscle_contribution(exercise_muscle_contribution, @invalid_attrs)
      assert exercise_muscle_contribution == Exercises.get_exercise_muscle_contribution!(exercise_muscle_contribution.id)
    end

    test "delete_exercise_muscle_contribution/1 deletes the exercise_muscle_contribution" do
      exercise_muscle_contribution = exercise_muscle_contribution_fixture()
      assert {:ok, %ExerciseMuscleContribution{}} = Exercises.delete_exercise_muscle_contribution(exercise_muscle_contribution)
      assert_raise Ecto.NoResultsError, fn -> Exercises.get_exercise_muscle_contribution!(exercise_muscle_contribution.id) end
    end

    test "change_exercise_muscle_contribution/1 returns a exercise_muscle_contribution changeset" do
      exercise_muscle_contribution = exercise_muscle_contribution_fixture()
      assert %Ecto.Changeset{} = Exercises.change_exercise_muscle_contribution(exercise_muscle_contribution)
    end
  end
end
