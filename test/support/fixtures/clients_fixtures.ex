defmodule Scopestrength.ClientsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Scopestrength.Clients` context.
  """

  @doc """
  Generate a client.
  """
  def client_fixture(attrs \\ %{}) do
    {:ok, client} =
      attrs
      |> Enum.into(%{

      })
      |> Scopestrength.Clients.create_client()

    client
  end
end
