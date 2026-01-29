defmodule Crohnjobs.NotificationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Crohnjobs.Notifications` context.
  """

  @doc """
  Generate a notification.
  """
  def notification_fixture(attrs \\ %{}) do
    {:ok, notification} =
      attrs
      |> Enum.into(%{

      })
      |> Crohnjobs.Notifications.create_notification()

    notification
  end
end
