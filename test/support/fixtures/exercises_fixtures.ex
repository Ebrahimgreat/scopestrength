defmodule Scopestrength.ExercisesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Scopestrength.Exercises` context.
  """

  @doc """
  Generate a muscles.
  """
  def muscles_fixture(attrs \\ %{}) do
    {:ok, muscles} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> Scopestrength.Exercises.create_muscles()

    muscles
  end

  @doc """
  Generate a equipment.
  """
  def equipment_fixture(attrs \\ %{}) do
    {:ok, equipment} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> Scopestrength.Exercises.create_equipment()

    equipment
  end

  @doc """
  Generate a exercise_muscle_contribution.
  """
  def exercise_muscle_contribution_fixture(attrs \\ %{}) do
    {:ok, exercise_muscle_contribution} =
      attrs
      |> Enum.into(%{

      })
      |> Scopestrength.Exercises.create_exercise_muscle_contribution()

    exercise_muscle_contribution
  end
end
