defmodule Crohnjobs.TrainingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Crohnjobs.Training` context.
  """

  @doc """
  Generate a workout.
  """
  def workout_fixture(attrs \\ %{}) do
    {:ok, workout} =
      attrs
      |> Enum.into(%{})
      |> Crohnjobs.Training.create_workout()

    workout
  end

  @doc """
  Generate a workout_details.
  """
  def workout_details_fixture(attrs \\ %{}) do
    {:ok, workout_details} =
      attrs
      |> Enum.into(%{})
      |> Crohnjobs.Training.create_workout_details()

    workout_details
  end
end
