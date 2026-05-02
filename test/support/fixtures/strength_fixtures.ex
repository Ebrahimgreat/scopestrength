defmodule Scopestrength.StrengthFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Scopestrength.Strength` context.
  """

  @doc """
  Generate a strength_progress.
  """
  def strength_progress_fixture(attrs \\ %{}) do
    {:ok, strength_progress} =
      attrs
      |> Enum.into(%{

      })
      |> Scopestrength.Strength.create_strength_progress()

    strength_progress
  end
end
