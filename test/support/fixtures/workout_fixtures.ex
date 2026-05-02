defmodule Scopestrength.WorkoutFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Scopestrength.Workout` context.
  """

  @doc """
  Generate a exercise.
  """
  def exercise_fixture(attrs \\ %{}) do
    {:ok, exercise} =
      attrs
      |> Enum.into(%{
        equipment: "some equipment",
        name: "some name",
        type: "some type"
      })
      |> Scopestrength.Workout.create_exercise()

    exercise
  end
end
