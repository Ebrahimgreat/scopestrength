defmodule Scopestrength.TrainersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Scopestrength.Trainers` context.
  """

  @doc """
  Generate a trainer.
  """
  def trainer_fixture(attrs \\ %{}) do
    {:ok, trainer} =
      attrs
      |> Enum.into(%{

      })
      |> Scopestrength.Trainers.create_trainer()

    trainer
  end
end
