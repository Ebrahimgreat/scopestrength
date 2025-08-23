defmodule Crohnjobs.TrainersTest do
  use Crohnjobs.DataCase

  alias Crohnjobs.Trainers

  describe "trainers" do
    alias Crohnjobs.Trainers.Trainer

    import Crohnjobs.TrainersFixtures

    @invalid_attrs %{}

    test "list_trainers/0 returns all trainers" do
      trainer = trainer_fixture()
      assert Trainers.list_trainers() == [trainer]
    end

    test "get_trainer!/1 returns the trainer with given id" do
      trainer = trainer_fixture()
      assert Trainers.get_trainer!(trainer.id) == trainer
    end

    test "create_trainer/1 with valid data creates a trainer" do
      valid_attrs = %{}

      assert {:ok, %Trainer{} = trainer} = Trainers.create_trainer(valid_attrs)
    end

    test "create_trainer/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Trainers.create_trainer(@invalid_attrs)
    end

    test "update_trainer/2 with valid data updates the trainer" do
      trainer = trainer_fixture()
      update_attrs = %{}

      assert {:ok, %Trainer{} = trainer} = Trainers.update_trainer(trainer, update_attrs)
    end

    test "update_trainer/2 with invalid data returns error changeset" do
      trainer = trainer_fixture()
      assert {:error, %Ecto.Changeset{}} = Trainers.update_trainer(trainer, @invalid_attrs)
      assert trainer == Trainers.get_trainer!(trainer.id)
    end

    test "delete_trainer/1 deletes the trainer" do
      trainer = trainer_fixture()
      assert {:ok, %Trainer{}} = Trainers.delete_trainer(trainer)
      assert_raise Ecto.NoResultsError, fn -> Trainers.get_trainer!(trainer.id) end
    end

    test "change_trainer/1 returns a trainer changeset" do
      trainer = trainer_fixture()
      assert %Ecto.Changeset{} = Trainers.change_trainer(trainer)
    end
  end
end
