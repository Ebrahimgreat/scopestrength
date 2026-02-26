defmodule Crohnjobs.ClientWeightsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Crohnjobs.ClientWeights` context.
  """

  @doc """
  Generate a client_weight.
  """
  def client_weight_fixture(attrs \\ %{}) do
    {:ok, client_weight} =
      attrs
      |> Enum.into(%{

      })
      |> Crohnjobs.ClientWeights.create_client_weight()

    client_weight
  end
end
