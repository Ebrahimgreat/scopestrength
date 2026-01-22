defmodule Crohnjobs.Training do
  @moduledoc """
  The Training context.
  """

  import Ecto.Query, warn: false
  alias Crohnjobs.Repo

  alias Crohnjobs.Training.Workout

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

  alias Crohnjobs.Training.WorkoutDetails

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
  Creates a workout from AI-generated response.
  Takes client_id and the AI response map with workout_name and exercises.
  """
  def create_workout_from_ai(client_id, ai_response) do
    Repo.transaction(fn ->
      workout_attrs = %{
        name: ai_response["workout_name"],
        date: DateTime.utc_now(),
        client_id: client_id
      }

      case create_workout(workout_attrs) do
        {:ok, workout} ->
          # Create workout details for each exercise/set
          details = create_workout_details_from_exercises(workout.id, ai_response["exercises"])
          case details do
            {:ok, _} -> workout
            {:error, reason} -> Repo.rollback(reason)
          end

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  defp create_workout_details_from_exercises(workout_id, exercises) when is_list(exercises) do
    results = Enum.flat_map(exercises, fn exercise ->
      exercise_id = find_exercise_id(exercise["name"])
      Enum.map(exercise["sets"], fn set ->
        attrs = %{
          workout_id: workout_id,
          exercise_id: exercise_id,
          set: set["set"],
          reps: set["reps"],
          weight: set["weight"]
        }
        create_workout_details(attrs)
      end)
    end)

    errors = Enum.filter(results, fn
      {:error, _} -> true
      _ -> false
    end)

    if Enum.empty?(errors) do
      {:ok, results}
    else
      {:error, :failed_to_create_details}
    end
  end

  defp create_workout_details_from_exercises(_, _), do: {:error, :invalid_exercises}

  def parse_note_into_workout(workout_id, note) do
    with {:ok, workout} <- fetch_workout(workout_id),
         {:ok, sets} <- Crohnjobs.AI.Gemini.parse_workout_note(note) do
      Repo.transaction(fn ->
        Enum.reduce_while(sets, {:ok, []}, fn set, {:ok, acc} ->
          attrs = build_detail_attrs(workout, set)

          case create_workout_details(attrs) do
            {:ok, detail} -> {:cont, {:ok, [detail | acc]}}
            {:error, reason} -> {:halt, {:error, reason}}
          end
        end)
        |> case do
          {:ok, details} -> {:ok, Enum.reverse(details)}
          {:error, reason} -> Repo.rollback(reason)
        end
      end)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp fetch_workout(workout_id) do
    case Repo.get(Workout, workout_id) do
      %Workout{} = workout -> {:ok, workout}
      _ -> {:error, :workout_not_found}
    end
  end

  defp build_detail_attrs(workout, set) do
    %{
      workout_id: workout.id,
      exercise_id: find_exercise_id(set[:exercise] || set["exercise"]),
      set: set[:set] || set["set"],
      reps: set[:reps] || set["reps"],
      weight: set[:weight] || set["weight"],
      rir: set[:rir] || set["rir"]
    }
  end

  defp find_exercise_id(nil), do: nil

  defp find_exercise_id(name) do
    Crohnjobs.Exercises.Exercise
    |> where([e], ilike(e.name, ^name))
    |> limit(1)
    |> Repo.one()
    |> case do
      nil -> nil
      exercise -> exercise.id
    end
  end
end
