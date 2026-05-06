defmodule Scopestrength.ClientRequestsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Scopestrength.ClientRequests` context.
  """

  @doc """
  Generate a client_request.
  """
  def client_request_fixture(attrs \\ %{}) do
    {:ok, client_request} =
      attrs
      |> Enum.into(%{

      })
      |> Scopestrength.ClientRequests.create_client_request()

    client_request
  end
end
