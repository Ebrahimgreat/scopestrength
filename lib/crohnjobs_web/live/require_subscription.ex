defmodule CrohnjobsWeb.RequireSubscription do
  import Phoenix.LiveView
  import Phoenix.Component
  alias Crohnjobs.Subscriptions
  alias Crohnjobs.Clients
  alias Crohnjobs.Trainers
  alias Crohnjobs.Account

  @moduledoc """
  LiveView on_mount hook to enforce active subscriptions.

  Usage:
      on_mount CrohnjobsWeb.RequireSubscription

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

      {:error, _reason} ->
        # No trainer found or no subscription - redirect to dedicated page
        {:halt, push_navigate(socket, to: "/trainer-subscription-expired")}
    end
  end

  defp check_subscription_access(socket, _user) do
    # Unknown role - deny access
    {:halt, redirect(socket, to: "/users/log_in")}
  end

  defp get_client_trainer_subscription(user_id) do
    with client when not is_nil(client) <- Clients.get_client_byUserId(user_id),
         trainer when not is_nil(trainer) <- Trainers.get_trainer!(client.trainer_id),
         trainer_user when not is_nil(trainer_user) <- Account.get_user!(trainer.user_id),
         subscription when not is_nil(subscription) <- Subscriptions.list_subscription_by_user_id(trainer_user) do
      trainer_name = trainer_user.name || trainer_user.email
      {:ok, subscription, trainer_name}
    else
      _ -> {:error, :not_found}
    end
  rescue
    _ -> {:error, :not_found}
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
