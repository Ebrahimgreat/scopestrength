defmodule ScopestrengthWeb.Client.TrainerSubscriptionExpired do
  use ScopestrengthWeb, :live_view

  @moduledoc """
  Page shown to clients when their trainer's subscription has expired.
  """

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-card flex items-center justify-center px-4">
      <div class="max-w-2xl w-full bg-card rounded-lg shadow-lg p-8">
        <div class="text-center">
          <div class="mx-auto flex items-center justify-center h-16 w-16 rounded-full bg-warning/10 mb-4">
            <svg
              class="h-10 w-10 text-warning"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
              />
            </svg>
          </div>

          <h1 class="text-3xl font-bold text-foreground mb-4">
            Access Temporarily Unavailable
          </h1>

          <p class="text-lg text-dim mb-8">
            Your trainer's subscription has expired or is not active
          </p>

          <div class="bg-warning/10 border border-warning rounded-lg p-6 mb-8 text-left">
            <h2 class="text-xl font-semibold text-foreground mb-4">
              What happened?
            </h2>
            <p class="text-foreground mb-4">
              Your access to ScopeStrength is provided through your trainer's subscription. Their subscription is currently not active, which temporarily prevents you from accessing the platform.
            </p>
            <p class="text-foreground mb-4">
              <strong>What you can do:</strong>
            </p>
            <ul class="list-disc list-inside text-foreground space-y-2 mb-4">
              <li>Contact your trainer to let them know</li>
              <li>Once they renew their subscription, you'll regain access immediately</li>
              <li>All your data and progress is safe and will be available when your trainer renews</li>
            </ul>
          </div>

          <div class="flex flex-col sm:flex-row gap-4 justify-center items-center border-t pt-6">
            <.link
              href={~p"/users/log_out"}
              method="delete"
              class="px-6 py-3 bg-gray-600 text-foreground font-semibold rounded-lg hover:bg-gray-700 transition-colors"
            >
              Log Out
            </.link>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
