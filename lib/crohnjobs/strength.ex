defmodule Crohnjobs.Strength do
  @moduledoc """
  The Strength context.
  """

  import Ecto.Query, warn: false
  alias Crohnjobs.Repo

  alias Crohnjobs.Strength.StrengthProgress

  @doc """
  Returns the list of strength_progress.

  ## Examples

      iex> list_strength_progress()
      [%StrengthProgress{}, ...]

  """
  def list_strength_progress do
    Repo.all(StrengthProgress)
  end

  @doc """
  Gets a single strength_progress.

  Raises `Ecto.NoResultsError` if the Strength progress does not exist.

  ## Examples

      iex> get_strength_progress!(123)
      %StrengthProgress{}

      iex> get_strength_progress!(456)
      ** (Ecto.NoResultsError)

  """
  def get_strength_progress!(id), do: Repo.get!(StrengthProgress, id)

  @doc """
  Creates a strength_progress.

  ## Examples

      iex> create_strength_progress(%{field: value})
      {:ok, %StrengthProgress{}}

      iex> create_strength_progress(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_strength_progress(attrs \\ %{}) do
    %StrengthProgress{}
    |> StrengthProgress.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a strength_progress.

  ## Examples

      iex> update_strength_progress(strength_progress, %{field: new_value})
      {:ok, %StrengthProgress{}}

      iex> update_strength_progress(strength_progress, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_strength_progress(%StrengthProgress{} = strength_progress, attrs) do
    strength_progress
    |> StrengthProgress.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a strength_progress.

  ## Examples

      iex> delete_strength_progress(strength_progress)
      {:ok, %StrengthProgress{}}

      iex> delete_strength_progress(strength_progress)
      {:error, %Ecto.Changeset{}}

  """
  def delete_strength_progress(%StrengthProgress{} = strength_progress) do
    Repo.delete(strength_progress)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking strength_progress changes.

  ## Examples

      iex> change_strength_progress(strength_progress)
      %Ecto.Changeset{data: %StrengthProgress{}}

  """
  def change_strength_progress(%StrengthProgress{} = strength_progress, attrs \\ %{}) do
    StrengthProgress.changeset(strength_progress, attrs)
  end
end
