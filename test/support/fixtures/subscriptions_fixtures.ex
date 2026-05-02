defmodule Scopestrength.SubscriptionsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Scopestrength.Subscriptions` context.
  """

  @doc """
  Generate a subscription.
  """
  def subscription_fixture(attrs \\ %{}) do
    {:ok, subscription} =
      attrs
      |> Enum.into(%{

      })
      |> Scopestrength.Subscriptions.create_subscription()

    subscription
  end
end
