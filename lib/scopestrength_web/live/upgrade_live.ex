defmodule ScopestrengthWeb.UpgradeLive do
  use ScopestrengthWeb, :live_view

  @moduledoc """
  Upgrade page for trainers to contact about subscription.
  """

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 flex items-center justify-center px-4">
      <div class="max-w-2xl w-full bg-white rounded-lg shadow-lg p-8">
        <div class="text-center">
          <div class="mx-auto flex items-center justify-center h-16 w-16 rounded-full bg-blue-100 mb-4">
            <svg class="h-10 w-10 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M13 10V3L4 14h7v7l9-11h-7z"
              />
            </svg>
          </div>

          <h1 class="text-3xl font-bold text-gray-900 mb-4">
            Upgrade to Pro
          </h1>

          <p class="text-lg text-gray-600 mb-8">
            Continue managing your clients with unlimited access
          </p>

          <div class="bg-blue-50 border border-blue-200 rounded-lg p-6 mb-8">
            <h2 class="text-xl font-semibold text-gray-900 mb-4">
              Get Started with Pro Membership
            </h2>
            <p class="text-gray-700 mb-4">
              To upgrade your account and unlock all features, please contact us:
            </p>
            <a
              href="mailto:ebrahim@scopestrength.com"
              class="inline-flex items-center gap-2 px-6 py-3 bg-blue-600 text-white font-semibold rounded-lg hover:bg-blue-700 transition-colors"
            >
              <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                <path d="M2.003 5.884L10 9.882l7.997-3.998A2 2 0 0016 4H4a2 2 0 00-1.997 1.884z" />
                <path d="M18 8.118l-8 4-8-4V14a2 2 0 002 2h12a2 2 0 002-2V8.118z" />
              </svg>
              ebrahim@scopestrength.com
            </a>
          </div>

          
          <div class="border-t pt-6 flex gap-4 justify-center">
            <.link
              href={~p"/users/log_out"}
              method="delete"
              class="px-6 py-3 bg-gray-600 text-white font-semibold rounded-lg hover:bg-gray-700 transition-colors"
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
