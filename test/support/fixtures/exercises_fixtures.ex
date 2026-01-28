defmodule Crohnjobs.ExercisesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Crohnjobs.Exercises` context.
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
      |> Crohnjobs.Exercises.create_muscles()

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
      |> Crohnjobs.Exercises.create_equipment()

    equipment
  end
end
