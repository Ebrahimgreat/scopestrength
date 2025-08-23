defmodule Crohnjobs.MeasurementsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Crohnjobs.Measurements` context.
  """

  @doc """
  Generate a measurement.
  """
  def measurement_fixture(attrs \\ %{}) do
    {:ok, measurement} =
      attrs
      |> Enum.into(%{

      })
      |> Crohnjobs.Measurements.create_measurement()

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
      |> Crohnjobs.Measurements.create_measurement_data()

    measurement_data
  end
end
