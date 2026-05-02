defmodule Scopestrength.ClientWeight do
  @moduledoc """
  The ClientWeight context.
  """

  import Ecto.Query, warn: false
  alias Scopestrength.Repo

  alias Scopestrength.ClientWeight.ClientWeights

  @doc """
  Returns the list of client_weight.

  ## Examples

      iex> list_client_weights()
      [%ClientWeights{}, ...]

  """
  def list_client_weights do
    Repo.all(ClientWeights)
  end

  def list_client_weights_for_client(client_id) do
    from(w in ClientWeights,
      where: w.client_id == ^client_id,
      order_by: [asc: w.date]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single client_weights.

  Raises `Ecto.NoResultsError` if the Client weight does not exist.

  ## Examples

      iex> get_client_weights!(123)
      %ClientWeights{}

      iex> get_client_weights!(456)
      ** (Ecto.NoResultsError)

  """
  def get_client_weights!(id), do: Repo.get!(ClientWeights, id)

  @doc """
  Creates a client_weights.

  ## Examples

      iex> create_client_weights(%{field: value})
      {:ok, %ClientWeights{}}

      iex> create_client_weights(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_client_weights(attrs \\ %{}) do
    %ClientWeights{}
    |> ClientWeights.changeset(attrs)
    |> Repo.insert()
  end

  def upsert_weight(client_id, date, weight) do
    case Repo.one(from w in ClientWeights, where: w.client_id == ^client_id and w.date == ^date) do
      nil ->
        create_client_weights(%{client_id: client_id, date: date, weight: weight})

      existing ->
        existing
        |> ClientWeights.changeset(%{weight: weight})
        |> Repo.update()
    end
  end

  @doc """
  Updates a client_weights.

  ## Examples

      iex> update_client_weights(client_weights, %{field: new_value})
      {:ok, %ClientWeights{}}

      iex> update_client_weights(client_weights, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_client_weights(%ClientWeights{} = client_weights, attrs) do
    client_weights
    |> ClientWeights.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a client_weights.

  ## Examples

      iex> delete_client_weights(client_weights)
      {:ok, %ClientWeights{}}

      iex> delete_client_weights(client_weights)
      {:error, %Ecto.Changeset{}}

  """
  def delete_client_weights(%ClientWeights{} = client_weights) do
    Repo.delete(client_weights)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking client_weights changes.

  ## Examples

      iex> change_client_weights(client_weights)
      %Ecto.Changeset{data: %ClientWeights{}}

  """
  def change_client_weights(%ClientWeights{} = client_weights, attrs \\ %{}) do
    ClientWeights.changeset(client_weights, attrs)
  end
end
