defmodule Crohnjobs.Measurements do
  @moduledoc """
  The Measurements context.
  """

  import Ecto.Query, warn: false
  alias Crohnjobs.Repo

  alias Crohnjobs.Measurements.Measurement

  @doc """
  Returns the list of measurements.

  ## Examples

      iex> list_measurements()
      [%Measurement{}, ...]

  """
  def list_measurements do
    Repo.all(Measurement)
  end

  @doc """
  Gets a single measurement.

  Raises `Ecto.NoResultsError` if the Measurement does not exist.

  ## Examples

      iex> get_measurement!(123)
      %Measurement{}

      iex> get_measurement!(456)
      ** (Ecto.NoResultsError)

  """
  def get_measurement!(id), do: Repo.get!(Measurement, id)

  @doc """
  Creates a measurement.

  ## Examples

      iex> create_measurement(%{field: value})
      {:ok, %Measurement{}}

      iex> create_measurement(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_measurement(attrs \\ %{}) do
    %Measurement{}
    |> Measurement.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a measurement.

  ## Examples

      iex> update_measurement(measurement, %{field: new_value})
      {:ok, %Measurement{}}

      iex> update_measurement(measurement, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_measurement(%Measurement{} = measurement, attrs) do
    measurement
    |> Measurement.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a measurement.

  ## Examples

      iex> delete_measurement(measurement)
      {:ok, %Measurement{}}

      iex> delete_measurement(measurement)
      {:error, %Ecto.Changeset{}}

  """
  def delete_measurement(%Measurement{} = measurement) do
    Repo.delete(measurement)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking measurement changes.

  ## Examples

      iex> change_measurement(measurement)
      %Ecto.Changeset{data: %Measurement{}}

  """
  def change_measurement(%Measurement{} = measurement, attrs \\ %{}) do
    Measurement.changeset(measurement, attrs)
  end

  alias Crohnjobs.Measurements.MeasurementData

  @doc """
  Returns the list of measurementdata.

  ## Examples

      iex> list_measurementdata()
      [%MeasurementData{}, ...]

  """
  def list_measurementdata do
    Repo.all(MeasurementData)
  end

  @doc """
  Gets a single measurement_data.

  Raises `Ecto.NoResultsError` if the Measurement data does not exist.

  ## Examples

      iex> get_measurement_data!(123)
      %MeasurementData{}

      iex> get_measurement_data!(456)
      ** (Ecto.NoResultsError)

  """
  def get_measurement_data!(id), do: Repo.get!(MeasurementData, id)

  @doc """
  Creates a measurement_data.

  ## Examples

      iex> create_measurement_data(%{field: value})
      {:ok, %MeasurementData{}}

      iex> create_measurement_data(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_measurement_data(attrs \\ %{}) do
    %MeasurementData{}
    |> MeasurementData.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a measurement_data.

  ## Examples

      iex> update_measurement_data(measurement_data, %{field: new_value})
      {:ok, %MeasurementData{}}

      iex> update_measurement_data(measurement_data, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_measurement_data(%MeasurementData{} = measurement_data, attrs) do
    measurement_data
    |> MeasurementData.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a measurement_data.

  ## Examples

      iex> delete_measurement_data(measurement_data)
      {:ok, %MeasurementData{}}

      iex> delete_measurement_data(measurement_data)
      {:error, %Ecto.Changeset{}}

  """
  def delete_measurement_data(%MeasurementData{} = measurement_data) do
    Repo.delete(measurement_data)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking measurement_data changes.

  ## Examples

      iex> change_measurement_data(measurement_data)
      %Ecto.Changeset{data: %MeasurementData{}}

  """
  def change_measurement_data(%MeasurementData{} = measurement_data, attrs \\ %{}) do
    MeasurementData.changeset(measurement_data, attrs)
  end
end
