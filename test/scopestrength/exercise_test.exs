defmodule Scopestrength.ExerciseTest do
  use Scopestrength.DataCase

  alias Scopestrength.Exercise

  describe "exercise_equipment" do
    alias Scopestrength.Exercise.ExerciseEquipment

    import Scopestrength.ExerciseFixtures

    @invalid_attrs %{}

    test "list_exercise_equipment/0 returns all exercise_equipment" do
      exercise_equipment = exercise_equipment_fixture()
      assert Exercise.list_exercise_equipment() == [exercise_equipment]
    end

    test "get_exercise_equipment!/1 returns the exercise_equipment with given id" do
      exercise_equipment = exercise_equipment_fixture()
      assert Exercise.get_exercise_equipment!(exercise_equipment.id) == exercise_equipment
    end


  end
end
