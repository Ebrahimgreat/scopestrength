defmodule Scopestrength.ClientWeightsTest do
  use Scopestrength.DataCase

  alias Scopestrength.ClientWeights

  describe "client_weight" do
    alias Scopestrength.ClientWeights.ClientWeight

    import Scopestrength.ClientWeightsFixtures

    @invalid_attrs %{}

    test "list_client_weight/0 returns all client_weight" do
      client_weight = client_weight_fixture()
      assert ClientWeights.list_client_weight() == [client_weight]
    end

    test "get_client_weight!/1 returns the client_weight with given id" do
      client_weight = client_weight_fixture()
      assert ClientWeights.get_client_weight!(client_weight.id) == client_weight
    end

    test "create_client_weight/1 with valid data creates a client_weight" do
      valid_attrs = %{}

      assert {:ok, %ClientWeight{} = client_weight} = ClientWeights.create_client_weight(valid_attrs)
    end

    test "create_client_weight/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = ClientWeights.create_client_weight(@invalid_attrs)
    end

    test "update_client_weight/2 with valid data updates the client_weight" do
      client_weight = client_weight_fixture()
      update_attrs = %{}

      assert {:ok, %ClientWeight{} = client_weight} = ClientWeights.update_client_weight(client_weight, update_attrs)
    end

    test "update_client_weight/2 with invalid data returns error changeset" do
      client_weight = client_weight_fixture()
      assert {:error, %Ecto.Changeset{}} = ClientWeights.update_client_weight(client_weight, @invalid_attrs)
      assert client_weight == ClientWeights.get_client_weight!(client_weight.id)
    end

    test "delete_client_weight/1 deletes the client_weight" do
      client_weight = client_weight_fixture()
      assert {:ok, %ClientWeight{}} = ClientWeights.delete_client_weight(client_weight)
      assert_raise Ecto.NoResultsError, fn -> ClientWeights.get_client_weight!(client_weight.id) end
    end

    test "change_client_weight/1 returns a client_weight changeset" do
      client_weight = client_weight_fixture()
      assert %Ecto.Changeset{} = ClientWeights.change_client_weight(client_weight)
    end
  end
end
