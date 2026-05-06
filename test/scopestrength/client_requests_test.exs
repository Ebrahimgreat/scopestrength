defmodule Scopestrength.ClientRequestsTest do
  use Scopestrength.DataCase

  alias Scopestrength.ClientRequests

  describe "client_requests" do
    alias Scopestrength.ClientRequests.ClientRequest

    import Scopestrength.ClientRequestsFixtures

    @invalid_attrs %{}

    test "list_client_requests/0 returns all client_requests" do
      client_request = client_request_fixture()
      assert ClientRequests.list_client_requests() == [client_request]
    end

    test "get_client_request!/1 returns the client_request with given id" do
      client_request = client_request_fixture()
      assert ClientRequests.get_client_request!(client_request.id) == client_request
    end

    test "create_client_request/1 with valid data creates a client_request" do
      valid_attrs = %{}

      assert {:ok, %ClientRequest{} = client_request} = ClientRequests.create_client_request(valid_attrs)
    end

    test "create_client_request/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = ClientRequests.create_client_request(@invalid_attrs)
    end

    test "update_client_request/2 with valid data updates the client_request" do
      client_request = client_request_fixture()
      update_attrs = %{}

      assert {:ok, %ClientRequest{} = client_request} = ClientRequests.update_client_request(client_request, update_attrs)
    end

    test "update_client_request/2 with invalid data returns error changeset" do
      client_request = client_request_fixture()
      assert {:error, %Ecto.Changeset{}} = ClientRequests.update_client_request(client_request, @invalid_attrs)
      assert client_request == ClientRequests.get_client_request!(client_request.id)
    end

    test "delete_client_request/1 deletes the client_request" do
      client_request = client_request_fixture()
      assert {:ok, %ClientRequest{}} = ClientRequests.delete_client_request(client_request)
      assert_raise Ecto.NoResultsError, fn -> ClientRequests.get_client_request!(client_request.id) end
    end

    test "change_client_request/1 returns a client_request changeset" do
      client_request = client_request_fixture()
      assert %Ecto.Changeset{} = ClientRequests.change_client_request(client_request)
    end
  end
end
