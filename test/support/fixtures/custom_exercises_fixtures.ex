defmodule Crohnjobs.CustomExercisesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Crohnjobs.CustomExercises` context.
  """

  @doc """
  Generate a custom_exercise.
  """
  def custom_exercise_fixture(attrs \\ %{}) do
    {:ok, custom_exercise} =
      attrs
      |> Enum.into(%{

      })
      |> Crohnjobs.CustomExercises.create_custom_exercise()

    custom_exercise
  end
end
