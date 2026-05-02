defmodule Scopestrength.TrainingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Scopestrength.Training` context.
  """

  @doc """
  Generate a workout.
  """
  def workout_fixture(attrs \\ %{}) do
    {:ok, workout} =
      attrs
      |> Enum.into(%{})
      |> Scopestrength.Training.create_workout()

    workout
  end

  @doc """
  Generate a workout_details.
  """
  def workout_details_fixture(attrs \\ %{}) do
    {:ok, workout_details} =
      attrs
      |> Enum.into(%{})
      |> Scopestrength.Training.create_workout_details()

    workout_details
  end

  @doc """
  Generate a set_type.
  """
  def set_type_fixture(attrs \\ %{}) do
    {:ok, set_type} =
      attrs
      |> Enum.into(%{
        description: "some description",
        name: "some name"
      })
      |> Scopestrength.Training.create_set_type()

    set_type
  end
end
