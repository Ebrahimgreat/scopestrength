defmodule Crohnjobs.Exercises do
  @moduledoc """
  The Exercises context.
  """

  import Ecto.Query, warn: false
  alias Crohnjobs.Repo

  alias Crohnjobs.Exercises.Muscles

  @doc """
  Returns the list of mucles.

  ## Examples

      iex> list_mucles()
      [%Muscles{}, ...]

  """
  def list_mucles do
    Repo.all(Muscles)
  end

  @doc """
  Gets a single muscles.

  Raises `Ecto.NoResultsError` if the Muscles does not exist.

  ## Examples

      iex> get_muscles!(123)
      %Muscles{}

      iex> get_muscles!(456)
      ** (Ecto.NoResultsError)

  """
  def get_muscles!(id), do: Repo.get!(Muscles, id)

  @doc """
  Creates a muscles.

  ## Examples

      iex> create_muscles(%{field: value})
      {:ok, %Muscles{}}

      iex> create_muscles(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_muscles(attrs \\ %{}) do
    %Muscles{}
    |> Muscles.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a muscles.

  ## Examples

      iex> update_muscles(muscles, %{field: new_value})
      {:ok, %Muscles{}}

      iex> update_muscles(muscles, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_muscles(%Muscles{} = muscles, attrs) do
    muscles
    |> Muscles.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a muscles.

  ## Examples

      iex> delete_muscles(muscles)
      {:ok, %Muscles{}}

      iex> delete_muscles(muscles)
      {:error, %Ecto.Changeset{}}

  """
  def delete_muscles(%Muscles{} = muscles) do
    Repo.delete(muscles)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking muscles changes.

  ## Examples

      iex> change_muscles(muscles)
      %Ecto.Changeset{data: %Muscles{}}

  """
  def change_muscles(%Muscles{} = muscles, attrs \\ %{}) do
    Muscles.changeset(muscles, attrs)
  end

  alias Crohnjobs.Exercises.Equipment

  @doc """
  Returns the list of equipment.

  ## Examples

      iex> list_equipment()
      [%Equipment{}, ...]

  """
  def list_equipment do
    Repo.all(Equipment)
  end

  @doc """
  Gets a single equipment.

  Raises `Ecto.NoResultsError` if the Equipment does not exist.

  ## Examples

      iex> get_equipment!(123)
      %Equipment{}

      iex> get_equipment!(456)
      ** (Ecto.NoResultsError)

  """
  def get_equipment!(id), do: Repo.get!(Equipment, id)

  @doc """
  Creates a equipment.

  ## Examples

      iex> create_equipment(%{field: value})
      {:ok, %Equipment{}}

      iex> create_equipment(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_equipment(attrs \\ %{}) do
    %Equipment{}
    |> Equipment.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a equipment.

  ## Examples

      iex> update_equipment(equipment, %{field: new_value})
      {:ok, %Equipment{}}

      iex> update_equipment(equipment, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_equipment(%Equipment{} = equipment, attrs) do
    equipment
    |> Equipment.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a equipment.

  ## Examples

      iex> delete_equipment(equipment)
      {:ok, %Equipment{}}

      iex> delete_equipment(equipment)
      {:error, %Ecto.Changeset{}}

  """
  def delete_equipment(%Equipment{} = equipment) do
    Repo.delete(equipment)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking equipment changes.

  ## Examples

      iex> change_equipment(equipment)
      %Ecto.Changeset{data: %Equipment{}}

  """
  def change_equipment(%Equipment{} = equipment, attrs \\ %{}) do
    Equipment.changeset(equipment, attrs)
  end
end
