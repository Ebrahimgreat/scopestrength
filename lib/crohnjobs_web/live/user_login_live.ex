defmodule CrohnjobsWeb.UserLoginLive do
  use CrohnjobsWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-gradient-to-b from-sky-50 to-white py-12 px-4">
      <div class="w-full max-w-md bg-white/95 backdrop-blur-sm shadow-2xl rounded-3xl p-8 border border-gray-100">
        <div class="flex items-center justify-center mb-6">
          <div class="flex items-center space-x-3">
            <div class="h-12 w-12 rounded-full bg-gradient-to-br from-brand to-indigo-600 flex items-center justify-center text-white font-extrabold text-lg shadow">CJ</div>
            <div class="text-2xl font-extrabold text-gray-800">Scope Application</div>
          </div>
        </div>

        <.header class="text-center mb-4">
          Sign in to your account
          <:subtitle>
            New here? <.link navigate={~p"/users/register"} class="font-semibold text-brand hover:underline">Create an account</.link>
          </:subtitle>
        </.header>

        <div class="space-y-4">
          <.simple_form for={@form} id="login_form" action={~p"/users/log_in"} phx-update="ignore">
            <.input field={@form[:email]} type="email" label="Email" placeholder="you@company.com" required class="rounded-md" />
            <.input field={@form[:password]} type="password" label="Password" placeholder="Enter your password" required class="rounded-md" />

            <:actions class="flex items-center justify-between mt-2">
              <div class="flex items-center space-x-2">
                <.input field={@form[:remember_me]} type="checkbox" label="" />
                <label for="user_remember_me" class="text-sm text-gray-600">Keep me logged in</label>
              </div>

              <.link href={~p"/users/reset_password"} class="text-sm font-medium text-gray-700 hover:underline">
                Forgot password?
              </.link>
            </:actions>

            <:actions class="mt-4">
              <.button phx-disable-with="Logging in..." class="w-full bg-gradient-to-r from-brand to-indigo-600 text-white font-medium shadow-md hover:opacity-95 py-2.5">
                Log in
              </.button>
            </:actions>

            <p class="mt-6 text-center text-xs text-gray-500">
              By signing in you agree to our <a href="#" class="underline">Terms</a> and <a href="#" class="underline">Privacy Policy</a>.
            </p>
          </.simple_form>
        </div>
      </div>
    </div>
    """  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end
