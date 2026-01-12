defmodule Crohnjobs.ChatFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Crohnjobs.Chat` context.
  """

  @doc """
  Generate a message.
  """
  def message_fixture(attrs \\ %{}) do
    {:ok, message} =
      attrs
      |> Enum.into(%{

      })
      |> Crohnjobs.Chat.create_message()

    message
  end
end
