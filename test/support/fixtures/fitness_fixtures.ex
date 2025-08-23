defmodule Crohnjobs.FitnessFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Crohnjobs.Fitness` context.
  """

  @doc """
  Generate a workout.
  """
  def workout_fixture(attrs \\ %{}) do
    {:ok, workout} =
      attrs
      |> Enum.into(%{

      })
      |> Crohnjobs.Fitness.create_workout()

    workout
  end

  @doc """
  Generate a workout_detail.
  """
  def workout_detail_fixture(attrs \\ %{}) do
    {:ok, workout_detail} =
      attrs
      |> Enum.into(%{

      })
      |> Crohnjobs.Fitness.create_workout_detail()

    workout_detail
  end
end
