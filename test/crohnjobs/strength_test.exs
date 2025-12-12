defmodule Crohnjobs.StrengthTest do
  use Crohnjobs.DataCase

  alias Crohnjobs.Strength

  describe "strength_progress" do
    alias Crohnjobs.Strength.StrengthProgress

    import Crohnjobs.StrengthFixtures

    @invalid_attrs %{}

    test "list_strength_progress/0 returns all strength_progress" do
      strength_progress = strength_progress_fixture()
      assert Strength.list_strength_progress() == [strength_progress]
    end

    test "get_strength_progress!/1 returns the strength_progress with given id" do
      strength_progress = strength_progress_fixture()
      assert Strength.get_strength_progress!(strength_progress.id) == strength_progress
    end

    test "create_strength_progress/1 with valid data creates a strength_progress" do
      valid_attrs = %{}

      assert {:ok, %StrengthProgress{} = strength_progress} = Strength.create_strength_progress(valid_attrs)
    end

    test "create_strength_progress/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Strength.create_strength_progress(@invalid_attrs)
    end

    test "update_strength_progress/2 with valid data updates the strength_progress" do
      strength_progress = strength_progress_fixture()
      update_attrs = %{}

      assert {:ok, %StrengthProgress{} = strength_progress} = Strength.update_strength_progress(strength_progress, update_attrs)
    end

    test "update_strength_progress/2 with invalid data returns error changeset" do
      strength_progress = strength_progress_fixture()
      assert {:error, %Ecto.Changeset{}} = Strength.update_strength_progress(strength_progress, @invalid_attrs)
      assert strength_progress == Strength.get_strength_progress!(strength_progress.id)
    end

    test "delete_strength_progress/1 deletes the strength_progress" do
      strength_progress = strength_progress_fixture()
      assert {:ok, %StrengthProgress{}} = Strength.delete_strength_progress(strength_progress)
      assert_raise Ecto.NoResultsError, fn -> Strength.get_strength_progress!(strength_progress.id) end
    end

    test "change_strength_progress/1 returns a strength_progress changeset" do
      strength_progress = strength_progress_fixture()
      assert %Ecto.Changeset{} = Strength.change_strength_progress(strength_progress)
    end
  end
end
