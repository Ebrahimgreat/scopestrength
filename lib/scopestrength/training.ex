defmodule Scopestrength.Training do
  @moduledoc """
  The Training context.
  """

  import Ecto.Query, warn: false
  alias Scopestrength.Repo

  alias Scopestrength.Training.Workout

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

  alias Scopestrength.Training.WorkoutDetails
  alias Scopestrength.Exercises.Exercise

  @doc """
  Returns the list of workout_details.

  ## Examples

      iex> list_workout_details()
      [%WorkoutDetails{}, ...]

  """
  def list_workout_details do
    Repo.all(WorkoutDetails)
  end

  @doc """
  Gets a single workout_details.

  Raises `Ecto.NoResultsError` if the Workout details does not exist.

  ## Examples

      iex> get_workout_details!(123)
      %WorkoutDetails{}

      iex> get_workout_details!(456)
      ** (Ecto.NoResultsError)

  """
  def get_workout_details!(id), do: Repo.get!(WorkoutDetails, id)

  @doc """
  Creates a workout_details.

  ## Examples

      iex> create_workout_details(%{field: value})
      {:ok, %WorkoutDetails{}}

      iex> create_workout_details(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_workout_details(attrs \\ %{}) do
    %WorkoutDetails{}
    |> WorkoutDetails.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a workout_details.

  ## Examples

      iex> update_workout_details(workout_details, %{field: new_value})
      {:ok, %WorkoutDetails{}}

      iex> update_workout_details(workout_details, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_workout_details(%WorkoutDetails{} = workout_details, attrs) do
    workout_details
    |> WorkoutDetails.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a workout_details.

  ## Examples

      iex> delete_workout_details(workout_details)
      {:ok, %WorkoutDetails{}}

      iex> delete_workout_details(workout_details)
      {:error, %Ecto.Changeset{}}

  """
  def delete_workout_details(%WorkoutDetails{} = workout_details) do
    Repo.delete(workout_details)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking workout_details changes.

  ## Examples

      iex> change_workout_details(workout_details)
      %Ecto.Changeset{data: %WorkoutDetails{}}

  """
  def change_workout_details(%WorkoutDetails{} = workout_details, attrs \\ %{}) do
    WorkoutDetails.changeset(workout_details, attrs)
  end

  @doc """
  Returns a progress summary for a client_id.
  """
  def progress_summary(client_id) do
    workouts_query =
      from w in Workout,
        where: w.client_id == ^client_id

    total_workouts = Repo.aggregate(workouts_query, :count, :id)

    last_workout =
      Repo.one(
        from w in workouts_query,
          order_by: [desc: fragment("COALESCE(?, ?)", w.date, w.inserted_at)],
          limit: 1
      )

    total_sets =
      Repo.aggregate(
        from(wd in WorkoutDetails,
          join: w in Workout,
          on: wd.workout_id == w.id,
          where: w.client_id == ^client_id
        ),
        :count,
        :id
      )

    pr =
      Repo.one(
        from wd in WorkoutDetails,
          join: w in Workout,
          on: wd.workout_id == w.id,
          join: e in Exercise,
          on: wd.exercise_id == e.id,
          where: w.client_id == ^client_id and not is_nil(wd.weight),
          order_by: [desc: wd.weight],
          limit: 1,
          select: %{
            weight: wd.weight,
            reps: wd.reps,
            exercise_name: e.name,
            date: wd.inserted_at
          }
      )

    {:ok,
     %{
       total_workouts: total_workouts,
       last_workout_at: last_workout && (last_workout.date || last_workout.inserted_at),
       total_sets: total_sets,
       pr: pr
     }}
  end


  alias Scopestrength.Training.SetType

  @doc """
  Returns the list of set_types.

  ## Examples

      iex> list_set_types()
      [%SetType{}, ...]

  """
  def list_set_types do
    Repo.all(SetType)
  end

  @doc """
  Gets a single set_type.

  Raises `Ecto.NoResultsError` if the Set type does not exist.

  ## Examples

      iex> get_set_type!(123)
      %SetType{}

      iex> get_set_type!(456)
      ** (Ecto.NoResultsError)

  """
  def get_set_type!(id), do: Repo.get!(SetType, id)

  @doc """
  Creates a set_type.

  ## Examples

      iex> create_set_type(%{field: value})
      {:ok, %SetType{}}

      iex> create_set_type(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_set_type(attrs \\ %{}) do
    %SetType{}
    |> SetType.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a set_type.

  ## Examples

      iex> update_set_type(set_type, %{field: new_value})
      {:ok, %SetType{}}

      iex> update_set_type(set_type, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_set_type(%SetType{} = set_type, attrs) do
    set_type
    |> SetType.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a set_type.

  ## Examples

      iex> delete_set_type(set_type)
      {:ok, %SetType{}}

      iex> delete_set_type(set_type)
      {:error, %Ecto.Changeset{}}

  """
  def delete_set_type(%SetType{} = set_type) do
    Repo.delete(set_type)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking set_type changes.

  ## Examples

      iex> change_set_type(set_type)
      %Ecto.Changeset{data: %SetType{}}

  """
  def change_set_type(%SetType{} = set_type, attrs \\ %{}) do
    SetType.changeset(set_type, attrs)
  end
end
