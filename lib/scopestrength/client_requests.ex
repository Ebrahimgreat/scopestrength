defmodule Scopestrength.ClientRequests do
  @moduledoc """
  The ClientRequests context.
  """

  import Ecto.Query, warn: false
  alias Scopestrength.Repo

  alias Scopestrength.ClientRequests.ClientRequest

  @doc """
  Returns the list of client_requests.

  ## Examples

      iex> list_client_requests()
      [%ClientRequest{}, ...]

  """


  def list_client_requests do
    Repo.all(ClientRequest)
  end

  @doc """
  Gets a single client_request.

  Raises `Ecto.NoResultsError` if the Client request does not exist.

  ## Examples

      iex> get_client_request!(123)
      %ClientRequest{}

      iex> get_client_request!(456)
      ** (Ecto.NoResultsError)

  """
  def get_client_request!(id), do: Repo.get!(ClientRequest, id)

  @doc """
  Creates a client_request.

  ## Examples

      iex> create_client_request(%{field: value})
      {:ok, %ClientRequest{}}

      iex> create_client_request(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_client_request(attrs \\ %{}) do
    %ClientRequest{}
    |> ClientRequest.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a client_request.

  ## Examples

      iex> update_client_request(client_request, %{field: new_value})
      {:ok, %ClientRequest{}}

      iex> update_client_request(client_request, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_client_request(%ClientRequest{} = client_request, attrs) do
    client_request
    |> ClientRequest.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a client_request.

  ## Examples

      iex> delete_client_request(client_request)
      {:ok, %ClientRequest{}}

      iex> delete_client_request(client_request)
      {:error, %Ecto.Changeset{}}

  """
  def delete_client_request(%ClientRequest{} = client_request) do
    Repo.delete(client_request)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking client_request changes.

  ## Examples

      iex> change_client_request(client_request)
      %Ecto.Changeset{data: %ClientRequest{}}

  """
  def change_client_request(%ClientRequest{} = client_request, attrs \\ %{}) do
    ClientRequest.changeset(client_request, attrs)
  end

  def list_requests_for_trainer(trainer_id) do
    Repo.all(
      from cr in ClientRequest,
        where: cr.trainer_id == ^trainer_id,
        order_by: [desc: cr.inserted_at],
        preload: [client: :user]
    )
  end

  def accept_request(request_id, trainer_id) do
    Repo.transaction(fn ->
      request = Repo.get!(ClientRequest, request_id)
      |> Repo.preload(:client)

      unless request.trainer_id == trainer_id, do: Repo.rollback(:unauthorized)

      {:ok, _} = request.client
        |> Scopestrength.Clients.Client.changeset(%{trainer_id: trainer_id})
        |> Repo.update()

      {:ok, updated} = request
        |> ClientRequest.changeset(%{status: "accepted"})
        |> Repo.update()

      updated
    end)
  end

  def reject_request(request_id, trainer_id) do
    request = Repo.get!(ClientRequest, request_id)
    unless request.trainer_id == trainer_id, do: raise "unauthorized"

    request
    |> ClientRequest.changeset(%{status: "rejected"})
    |> Repo.update()
  end
end
