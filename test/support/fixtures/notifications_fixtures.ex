defmodule Scopestrength.NotificationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Scopestrength.Notifications` context.
  """

  @doc """
  Generate a notification.
  """
  def notification_fixture(attrs \\ %{}) do
    {:ok, notification} =
      attrs
      |> Enum.into(%{

      })
      |> Scopestrength.Notifications.create_notification()

    notification
  end
end
