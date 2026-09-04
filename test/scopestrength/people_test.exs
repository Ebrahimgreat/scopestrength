defmodule Scopestrength.PeopleTest do
  use Scopestrength.DataCase, async: true

  import Scopestrength.AccountFixtures
  import Scopestrength.PeopleFixtures

  alias Scopestrength.{Clients, Trainers}

  describe "trainers" do
    test "create_trainer/1 links to a user and is found by user id" do
      user = trainer_user_fixture()
      {:ok, trainer} = Trainers.create_trainer(%{user_id: user.id, bio: "Hi", specialization: "Power"})

      assert Trainers.get_trainer_byUserId(user.id).id == trainer.id
      assert Trainers.get_trainer!(trainer.id).specialization == "Power"
      assert trainer.id in Enum.map(Trainers.list_trainers(), & &1.id)
    end

    test "update_trainer/2 and delete_trainer/1" do
      trainer = trainer_fixture()
      {:ok, trainer} = Trainers.update_trainer(trainer, %{bio: "Updated"})
      assert trainer.bio == "Updated"
      {:ok, _} = Trainers.delete_trainer(trainer)
      assert_raise Ecto.NoResultsError, fn -> Trainers.get_trainer!(trainer.id) end
    end

    test "change_trainer/1 returns a changeset" do
      assert %Ecto.Changeset{} = Trainers.change_trainer(trainer_fixture())
    end
  end

  describe "clients" do
    test "client_fixture creates a client attached to a trainer" do
      client = client_fixture()
      assert client.trainer_id
      assert client.user.role == "client"
      assert Clients.get_client_byUserId(client.user_id).id == client.id
    end

    test "get_clients_for_trainer/1 returns only that trainer's clients" do
      trainer = trainer_fixture()
      other = trainer_fixture()
      mine = client_fixture(%{trainer: trainer})
      _theirs = client_fixture(%{trainer: other})

      ids = trainer.id |> Clients.get_clients_for_trainer() |> Enum.map(& &1.id)
      assert ids == [mine.id]
    end

    test "update_client/2 and delete_client/1" do
      client = client_fixture()
      {:ok, client} = Clients.update_client(client, %{age: 41, notes: "Knee"})
      assert client.age == 41
      assert client.notes == "Knee"
      {:ok, _} = Clients.delete_client(client)
      assert_raise Ecto.NoResultsError, fn -> Clients.get_client!(client.id) end
    end

    test "change_client/1 returns a changeset" do
      assert %Ecto.Changeset{} = Clients.change_client(client_fixture())
    end
  end
end
