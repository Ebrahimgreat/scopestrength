defmodule ScopestrengthWeb.RequireSubscription do
  import Phoenix.LiveView
  import Phoenix.Component
  alias Scopestrength.Subscriptions
  alias Scopestrength.Clients
  alias Scopestrength.Trainers
  alias Scopestrength.Account

  @moduledoc """
  LiveView on_mount hook to enforce active subscriptions.

  Usage:
      on_mount ScopestrengthWeb.RequireSubscription

  This hook checks:
  - For trainers: Their own subscription must be active
  - For clients: Their trainer's subscription must be active
  """

  def on_mount(:default, _params, _session, socket) do
    case socket.assigns.current_user do
      nil ->
        {:halt, redirect(socket, to: "/users/log_in")}

      user ->
        check_subscription_access(socket, user)
    end
  end

  defp check_subscription_access(socket, %{role: "trainer"} = user) do
    case Subscriptions.list_subscription_by_user_id(user) do
      nil ->
        # No subscription found - redirect to upgrade
        {:halt, push_navigate(socket, to: "/upgrade")}

      subscription ->
        if Subscriptions.in_trial?(subscription) || has_paid_access?(subscription) do
          # Active subscription - allow access
          days_remaining = Subscriptions.trial_remaining(subscription)

          socket =
            socket
            |> assign(:subscription, subscription)
            |> assign(:trial_days_remaining, days_remaining)
            |> assign(:subscription_status, get_status(subscription))

          {:cont, socket}
        else
          # Expired - redirect to upgrade
          {:halt, push_navigate(socket, to: "/upgrade")}
        end
    end
  end

  defp check_subscription_access(socket, %{role: "client"} = user) do
    # Clients don't have their own subscription - check their trainer's
    case get_client_trainer_subscription(user.id) do
      {:ok, subscription, trainer_name} ->
        if Subscriptions.in_trial?(subscription) || has_paid_access?(subscription) do
          # Trainer has active subscription - client has access
          socket =
            socket
            |> assign(:subscription, subscription)
            |> assign(:trainer_name, trainer_name)
            |> assign(:subscription_status, :via_trainer)

          {:cont, socket}
        else
          # Trainer's subscription expired - redirect to dedicated page
          {:halt, push_navigate(socket, to: "/trainer-subscription-expired")}
        end

      {:error, :no_trainer} ->
        # A client who has not redeemed an invite code yet has no trainer, which
        # is the normal state after signup — not an expired subscription. Let
        # them through so they can reach the invite form on the dashboard;
        # otherwise there is no route out of the expired page.
        {:cont, assign(socket, :subscription_status, :no_trainer)}

      {:error, _reason} ->
        # Trainer exists but has no subscription record - treat as expired.
        {:halt, push_navigate(socket, to: "/trainer-subscription-expired")}
    end
  end

  defp check_subscription_access(socket, _user) do
    # Unknown role - deny access
    {:halt, redirect(socket, to: "/users/log_in")}
  end

  defp get_client_trainer_subscription(user_id) do
    client = Clients.get_client_byUserId(user_id)

    # Checked before the lookup below: get_trainer!/1 raises on a nil id, and
    # the old rescue turned that into the same :not_found as a genuinely
    # missing subscription, so unlinked clients were shown the expiry page.
    if is_nil(client) or is_nil(client.trainer_id) do
      {:error, :no_trainer}
    else
      with trainer when not is_nil(trainer) <- Trainers.get_trainer!(client.trainer_id),
           trainer_user when not is_nil(trainer_user) <- Account.get_user!(trainer.user_id),
           subscription when not is_nil(subscription) <-
             Subscriptions.list_subscription_by_user_id(trainer_user) do
        {:ok, subscription, trainer_user.name || trainer_user.email}
      else
        _ -> {:error, :not_found}
      end
    end
  rescue
    # Clients.get_client_byUserId/1 uses get_by! and raises when the user has no
    # client record at all, which is also a "not linked yet" state.
    Ecto.NoResultsError -> {:error, :no_trainer}
  end

  defp has_paid_access?(subscription) do
    if subscription.paid_until do
      DateTime.compare(DateTime.utc_now(), subscription.paid_until) == :lt
    else
      false
    end
  end

  defp get_status(subscription) do
    cond do
      Subscriptions.in_trial?(subscription) -> :trial
      has_paid_access?(subscription) -> :paid
      true -> :expired
    end
  end
end
