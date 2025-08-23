defmodule Crohnjobs.MeasurementsTest do
  use Crohnjobs.DataCase

  alias Crohnjobs.Measurements

  describe "measurements" do
    alias Crohnjobs.Measurements.Measurement

    import Crohnjobs.MeasurementsFixtures

    @invalid_attrs %{}

    test "list_measurements/0 returns all measurements" do
      measurement = measurement_fixture()
      assert Measurements.list_measurements() == [measurement]
    end

    test "get_measurement!/1 returns the measurement with given id" do
      measurement = measurement_fixture()
      assert Measurements.get_measurement!(measurement.id) == measurement
    end

    test "create_measurement/1 with valid data creates a measurement" do
      valid_attrs = %{}

      assert {:ok, %Measurement{} = measurement} = Measurements.create_measurement(valid_attrs)
    end

    test "create_measurement/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Measurements.create_measurement(@invalid_attrs)
    end

    test "update_measurement/2 with valid data updates the measurement" do
      measurement = measurement_fixture()
      update_attrs = %{}

      assert {:ok, %Measurement{} = measurement} = Measurements.update_measurement(measurement, update_attrs)
    end

    test "update_measurement/2 with invalid data returns error changeset" do
      measurement = measurement_fixture()
      assert {:error, %Ecto.Changeset{}} = Measurements.update_measurement(measurement, @invalid_attrs)
      assert measurement == Measurements.get_measurement!(measurement.id)
    end

    test "delete_measurement/1 deletes the measurement" do
      measurement = measurement_fixture()
      assert {:ok, %Measurement{}} = Measurements.delete_measurement(measurement)
      assert_raise Ecto.NoResultsError, fn -> Measurements.get_measurement!(measurement.id) end
    end

    test "change_measurement/1 returns a measurement changeset" do
      measurement = measurement_fixture()
      assert %Ecto.Changeset{} = Measurements.change_measurement(measurement)
    end
  end

  describe "measurementdata" do
    alias Crohnjobs.Measurements.MeasurementData

    import Crohnjobs.MeasurementsFixtures

    @invalid_attrs %{}

    test "list_measurementdata/0 returns all measurementdata" do
      measurement_data = measurement_data_fixture()
      assert Measurements.list_measurementdata() == [measurement_data]
    end

    test "get_measurement_data!/1 returns the measurement_data with given id" do
      measurement_data = measurement_data_fixture()
      assert Measurements.get_measurement_data!(measurement_data.id) == measurement_data
    end

    test "create_measurement_data/1 with valid data creates a measurement_data" do
      valid_attrs = %{}

      assert {:ok, %MeasurementData{} = measurement_data} = Measurements.create_measurement_data(valid_attrs)
    end

    test "create_measurement_data/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Measurements.create_measurement_data(@invalid_attrs)
    end

    test "update_measurement_data/2 with valid data updates the measurement_data" do
      measurement_data = measurement_data_fixture()
      update_attrs = %{}

      assert {:ok, %MeasurementData{} = measurement_data} = Measurements.update_measurement_data(measurement_data, update_attrs)
    end

    test "update_measurement_data/2 with invalid data returns error changeset" do
      measurement_data = measurement_data_fixture()
      assert {:error, %Ecto.Changeset{}} = Measurements.update_measurement_data(measurement_data, @invalid_attrs)
      assert measurement_data == Measurements.get_measurement_data!(measurement_data.id)
    end

    test "delete_measurement_data/1 deletes the measurement_data" do
      measurement_data = measurement_data_fixture()
      assert {:ok, %MeasurementData{}} = Measurements.delete_measurement_data(measurement_data)
      assert_raise Ecto.NoResultsError, fn -> Measurements.get_measurement_data!(measurement_data.id) end
    end

    test "change_measurement_data/1 returns a measurement_data changeset" do
      measurement_data = measurement_data_fixture()
      assert %Ecto.Changeset{} = Measurements.change_measurement_data(measurement_data)
    end
  end
end
