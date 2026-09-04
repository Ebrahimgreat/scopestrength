defmodule Scopestrength.ExercisesTest do
  use Scopestrength.DataCase, async: true

  import Scopestrength.ExercisesFixtures
  import Scopestrength.PeopleFixtures

  alias Scopestrength.{Exercise, Exercises}

  describe "muscles and equipment" do
    test "require a name" do
      {:error, changeset} = Exercises.create_muscles(%{})
      assert %{name: ["can't be blank"]} = errors_on(changeset)
      {:error, changeset} = Exercises.create_equipment(%{})
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "are listed, updated and deleted" do
      muscle = muscles_fixture(%{name: "Quads"})
      equipment = equipment_fixture(%{name: "Barbell"})

      assert muscle.id in Enum.map(Exercises.list_mucles(), & &1.id)
      assert equipment.id in Enum.map(Exercises.list_equipment(), & &1.id)

      {:ok, muscle} = Exercises.update_muscles(muscle, %{name: "Quadriceps"})
      assert Exercises.get_muscles!(muscle.id).name == "Quadriceps"

      {:ok, _} = Exercises.delete_equipment(equipment)
      assert_raise Ecto.NoResultsError, fn -> Exercises.get_equipment!(equipment.id) end
    end
  end

  describe "exercises" do
    test "require name, muscle and equipment" do
      {:error, changeset} = Exercise.create_exercise(%{})
      assert %{name: ["can't be blank"], muscle_id: ["can't be blank"], equipment_id: ["can't be blank"]} = errors_on(changeset)
    end

    test "can be created, updated and deleted" do
      exercise = exercise_fixture(%{name: "Bench Press"})
      assert exercise.muscle
      assert exercise.equipment
      refute exercise.is_unilateral

      {:ok, exercise} = Exercise.update_exercise(exercise, %{is_unilateral: true})
      assert Exercise.get_exercise!(exercise.id).is_unilateral

      {:ok, _} = Exercise.delete_exercise(exercise)
      assert_raise Ecto.NoResultsError, fn -> Exercise.get_exercise!(exercise.id) end
    end

    test "unilateral_exercise_fixture sets the flag" do
      assert unilateral_exercise_fixture().is_unilateral
    end
  end

  describe "muscle contributions" do
    test "require muscle, exercise, role and multiplier" do
      {:error, changeset} = Exercises.create_exercise_muscle_contribution(%{})
      errors = errors_on(changeset)
      assert errors.muscle_id == ["can't be blank"]
      assert errors.exercise_id == ["can't be blank"]
      assert errors.role == ["can't be blank"]
      assert errors.multiplier == ["can't be blank"]
    end

    test "can be created for a trainer and updated" do
      trainer = trainer_fixture()
      exercise = exercise_fixture()
      secondary = muscles_fixture()

      contribution =
        exercise_muscle_contribution_fixture(%{
          exercise: exercise,
          muscle_id: secondary.id,
          role: "secondary",
          multiplier: 0.5,
          trainer_id: trainer.id
        })

      assert contribution.trainer_id == trainer.id
      {:ok, updated} = Exercises.update_exercise_muscle_contribution(contribution, %{multiplier: 0.75})
      assert Exercises.get_exercise_muscle_contribution!(updated.id).multiplier == 0.75
      assert updated.id in Enum.map(Exercises.list_exercise_muscle_contribution(), & &1.id)
      {:ok, _} = Exercises.delete_exercise_muscle_contribution(updated)
    end
  end
end
