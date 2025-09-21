defmodule Crohnjobs.CustomExercises do
  @moduledoc """
  The CustomExercises context.
  """

  import Ecto.Query, warn: false
  alias Crohnjobs.Repo

  alias Crohnjobs.CustomExercises.CustomExercise

  @doc """
  Returns the list of custom_exercises.

  ## Examples

      iex> list_custom_exercises()
      [%CustomExercise{}, ...]

  """
  def list_custom_exercises do
    Repo.all(CustomExercise)
  end

  @doc """
  Gets a single custom_exercise.

  Raises `Ecto.NoResultsError` if the Custom exercise does not exist.

  ## Examples

      iex> get_custom_exercise!(123)
      %CustomExercise{}

      iex> get_custom_exercise!(456)
      ** (Ecto.NoResultsError)

  """
  def get_custom_exercise!(id), do: Repo.get!(CustomExercise, id)

  @doc """
  Creates a custom_exercise.

  ## Examples

      iex> create_custom_exercise(%{field: value})
      {:ok, %CustomExercise{}}

      iex> create_custom_exercise(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_custom_exercise(attrs \\ %{}) do
    %CustomExercise{}
    |> CustomExercise.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a custom_exercise.

  ## Examples

      iex> update_custom_exercise(custom_exercise, %{field: new_value})
      {:ok, %CustomExercise{}}

      iex> update_custom_exercise(custom_exercise, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_custom_exercise(%CustomExercise{} = custom_exercise, attrs) do
    custom_exercise
    |> CustomExercise.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a custom_exercise.

  ## Examples

      iex> delete_custom_exercise(custom_exercise)
      {:ok, %CustomExercise{}}

      iex> delete_custom_exercise(custom_exercise)
      {:error, %Ecto.Changeset{}}

  """
  def delete_custom_exercise(%CustomExercise{} = custom_exercise) do
    Repo.delete(custom_exercise)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking custom_exercise changes.

  ## Examples

      iex> change_custom_exercise(custom_exercise)
      %Ecto.Changeset{data: %CustomExercise{}}

  """
  def change_custom_exercise(%CustomExercise{} = custom_exercise, attrs \\ %{}) do
    CustomExercise.changeset(custom_exercise, attrs)
  end
end
