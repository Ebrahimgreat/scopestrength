defmodule Crohnjobs.Fitness do
  @moduledoc """
  The Fitness context.
  """

  import Ecto.Query, warn: false
  alias Crohnjobs.Repo

  alias Crohnjobs.Fitness.Workout

  @doc """
  Returns the list of workouts.

  ## Examples

      iex> list_workouts()
      [%Workout{}, ...]

  """
  def list_workouts do
    Repo.all(Workout)
  end

  @doc """
  Gets a single workout.

  Raises `Ecto.NoResultsError` if the Workout does not exist.

  ## Examples

      iex> get_workout!(123)
      %Workout{}

      iex> get_workout!(456)
      ** (Ecto.NoResultsError)

  """
  def get_workout!(id), do: Repo.get!(Workout, id)

  @doc """
  Creates a workout.

  ## Examples

      iex> create_workout(%{field: value})
      {:ok, %Workout{}}

      iex> create_workout(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_workout(attrs \\ %{}) do
    %Workout{}
    |> Workout.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a workout.

  ## Examples

      iex> update_workout(workout, %{field: new_value})
      {:ok, %Workout{}}

      iex> update_workout(workout, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_workout(%Workout{} = workout, attrs) do
    workout
    |> Workout.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a workout.

  ## Examples

      iex> delete_workout(workout)
      {:ok, %Workout{}}

      iex> delete_workout(workout)
      {:error, %Ecto.Changeset{}}

  """
  def delete_workout(%Workout{} = workout) do
    Repo.delete(workout)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking workout changes.

  ## Examples

      iex> change_workout(workout)
      %Ecto.Changeset{data: %Workout{}}

  """
  def change_workout(%Workout{} = workout, attrs \\ %{}) do
    Workout.changeset(workout, attrs)
  end

  alias Crohnjobs.Fitness.WorkoutDetail

  @doc """
  Returns the list of workout_details.

  ## Examples

      iex> list_workout_details()
      [%WorkoutDetaial{}, ...]

  """
  def list_workout_details do
    Repo.all(WorkoutDetail)
  end

  @doc """
  Gets a single workout_detaial.

  Raises `Ecto.NoResultsError` if the Workout detail does not exist.

  ## Examples

      iex> get_workout_detaial!(123)
      %WorkoutDetaial{}

      iex> get_workout_detaial!(456)
      ** (Ecto.NoResultsError)

  """
  def get_workout_detail!(id), do: Repo.get!(WorkoutDetail, id)

  @doc """
  Creates a workout_detaial.

  ## Examples

      iex> create_workout_detaial(%{field: value})
      {:ok, %WorkoutDetaial{}}

      iex> create_workout_detaial(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_workout_detail(attrs \\ %{}) do
    %WorkoutDetail{}
    |> WorkoutDetail.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a workout_detaial.

  ## Examples

      iex> update_workout_detaial(workout_detaial, %{field: new_value})
      {:ok, %WorkoutDetaial{}}

      iex> update_workout_detaial(workout_detaial, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_workout_detaial(%WorkoutDetail{} = workout_detail, attrs) do
    workout_detail
    |> WorkoutDetail.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a workout_detaial.

  ## Examples

      iex> delete_workout_detaial(workout_detaial)
      {:ok, %WorkoutDetaial{}}

      iex> delete_workout_detaial(workout_detaial)
      {:error, %Ecto.Changeset{}}

  """
  def delete_workout_detaial(%WorkoutDetail{} = workout_detail) do
    Repo.delete(workout_detail)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking workout_detaial changes.

  ## Examples

      iex> change_workout_detaial(workout_detaial)
      %Ecto.Changeset{data: %WorkoutDetaial{}}

  """
  def change_workout_detaial(%WorkoutDetail{} = workout_detail, attrs \\ %{}) do
    WorkoutDetail.changeset(workout_detail, attrs)
  end
end
