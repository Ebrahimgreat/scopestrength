defmodule Scopestrength.ChatFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Scopestrength.Chat` context.
  """

  @doc """
  Generate a message.
  """
  def message_fixture(attrs \\ %{}) do
    {:ok, message} =
      attrs
      |> Enum.into(%{

      })
      |> Scopestrength.Chat.create_message()

    message
  end
end
