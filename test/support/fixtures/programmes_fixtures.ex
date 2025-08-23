defmodule Crohnjobs.ProgrammesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Crohnjobs.Programmes` context.
  """

  @doc """
  Generate a programme.
  """
  def programme_fixture(attrs \\ %{}) do
    {:ok, programme} =
      attrs
      |> Enum.into(%{

      })
      |> Crohnjobs.Programmes.create_programme()

    programme
  end

  @doc """
  Generate a programme_details.
  """
  def programme_details_fixture(attrs \\ %{}) do
    {:ok, programme_details} =
      attrs
      |> Enum.into(%{

      })
      |> Crohnjobs.Programmes.create_programme_details()

    programme_details
  end

  @doc """
  Generate a programme_template.
  """
  def programme_template_fixture(attrs \\ %{}) do
    {:ok, programme_template} =
      attrs
      |> Enum.into(%{

      })
      |> Crohnjobs.Programmes.create_programme_template()

    programme_template
  end

  @doc """
  Generate a programme_user.
  """
  def programme_user_fixture(attrs \\ %{}) do
    {:ok, programme_user} =
      attrs
      |> Enum.into(%{

      })
      |> Crohnjobs.Programmes.create_programme_user()

    programme_user
  end
end
