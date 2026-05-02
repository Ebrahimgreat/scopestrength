defmodule Scopestrength.MeasurementsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Scopestrength.Measurements` context.
  """

  @doc """
  Generate a measurement.
  """
  def measurement_fixture(attrs \\ %{}) do
    {:ok, measurement} =
      attrs
      |> Enum.into(%{

      })
      |> Scopestrength.Measurements.create_measurement()

    measurement
  end

  @doc """
  Generate a measurement_data.
  """
  def measurement_data_fixture(attrs \\ %{}) do
    {:ok, measurement_data} =
      attrs
      |> Enum.into(%{

      })
      |> Scopestrength.Measurements.create_measurement_data()

    measurement_data
  end
end
