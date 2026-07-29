defmodule ScopestrengthWeb.SubscriptionBanner do
  use Phoenix.Component

  @moduledoc """
  Displays subscription status banner for trainers.
  Shows trial days remaining or membership status.
  """

  attr :subscription_status, :atom, required: true
  attr :trial_days_remaining, :integer, default: 0
  attr :current_user, :map, required: true

  def subscription_banner(assigns) do
    ~H"""
    <!-- Only show for trainers -->
    <div :if={@current_user.role == "trainer"} class="w-full">
      <!-- Trial Status -->
      <div
        :if={@subscription_status == :trial}
        class={[
          "px-4 py-2 text-sm font-medium flex flex-wrap items-center justify-between gap-2",
          trial_color(@trial_days_remaining)
        ]}
      >
        <div class="flex items-center gap-2">
          <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
            <path
              fill-rule="evenodd"
              d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-12a1 1 0 10-2 0v4a1 1 0 00.293.707l2.828 2.829a1 1 0 101.415-1.415L11 9.586V6z"
              clip-rule="evenodd"
            />
          </svg>
          <span>
            Trial: <%= trial_message(@trial_days_remaining) %>
          </span>
        </div>

        <a
          href="/upgrade"
          class="px-3 py-1 bg-card/20 hover:bg-card/30 rounded-md font-semibold transition-colors"
        >
          Upgrade Now
        </a>
      </div>
      <!-- Paid Member Status -->
      <div
        :if={@subscription_status == :paid}
        class="px-4 py-2 bg-primary text-foreground text-sm font-medium flex flex-wrap items-center justify-between gap-2"
      >
        <div class="flex items-center gap-2">
          <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
            <path
              fill-rule="evenodd"
              d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
              clip-rule="evenodd"
            />
          </svg>
          <span>Pro Member - All features unlocked</span>
        </div>

        <a href="/settings" class="hover:underline">
          Manage Subscription
        </a>
      </div>
    </div>
    """
  end

  defp trial_message(days) when days > 1, do: "#{days} days remaining"
  defp trial_message(1), do: "Last day - Upgrade today!"
  defp trial_message(0), do: "Expires today!"
  defp trial_message(_), do: "Trial expired"

  defp trial_color(days) when days >= 10, do: "bg-primary text-foreground"
  defp trial_color(days) when days >= 4, do: "bg-warning text-foreground"
  defp trial_color(days) when days >= 1, do: "bg-warning text-foreground"
  defp trial_color(_), do: "bg-danger text-foreground"
end
