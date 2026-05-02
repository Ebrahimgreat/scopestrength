defmodule Scopestrength.ClientNoteFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Scopestrength.ClientNote` context.
  """

  @doc """
  Generate a client_notes.
  """
  def client_notes_fixture(attrs \\ %{}) do
    {:ok, client_notes} =
      attrs
      |> Enum.into(%{

      })
      |> Scopestrength.ClientNote.create_client_notes()

    client_notes
  end
end
