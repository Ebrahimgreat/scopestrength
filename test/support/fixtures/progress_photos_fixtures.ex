defmodule Scopestrength.ProgressPhotosFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Scopestrength.ProgressPhotos` context.
  """

  @doc """
  Generate a progress_photo.
  """
  def progress_photo_fixture(attrs \\ %{}) do
    {:ok, progress_photo} =
      attrs
      |> Enum.into(%{
        date: ~U[2026-01-31 12:34:00Z],
        notes: "some notes",
        photo_url: "some photo_url"
      })
      |> Scopestrength.ProgressPhotos.create_progress_photo()

    progress_photo
  end
end
