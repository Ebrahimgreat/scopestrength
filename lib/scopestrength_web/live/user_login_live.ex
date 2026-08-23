defmodule ScopestrengthWeb.UserLoginLive do
  use ScopestrengthWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="flex min-h-screen items-center justify-center px-4 py-12">
      <div class="w-full max-w-sm">
        <div class="text-center">
          <p class="text-xs font-medium uppercase tracking-widest text-dim">Scope Strength</p>
          <h1 class="mt-2 font-display text-5xl font-bold uppercase tracking-wide text-foreground">
            Sign in
          </h1>
        </div>

        <.form
          for={@form}
          id="login_form"
          action={~p"/users/log_in"}
          phx-update="ignore"
          class="mt-8 space-y-4"
        >
          <div>
            <label for="user_email" class="mb-1 block text-xs uppercase tracking-widest text-dim">
              Email
            </label>
            <input
              type="email"
              name={@form[:email].name}
              id="user_email"
              value={Phoenix.HTML.Form.normalize_value("email", @form[:email].value)}
              placeholder="you@company.com"
              required
              autocomplete="email"
              class="w-full rounded-md border-line bg-muted px-3 py-2.5 text-sm text-foreground placeholder:text-faint focus:border-primary focus:ring-0"
            />
          </div>

          <div>
            <label for="user_password" class="mb-1 block text-xs uppercase tracking-widest text-dim">
              Password
            </label>
            <input
              type="password"
              name={@form[:password].name}
              id="user_password"
              placeholder="Enter your password"
              required
              autocomplete="current-password"
              class="w-full rounded-md border-line bg-muted px-3 py-2.5 text-sm text-foreground placeholder:text-faint focus:border-primary focus:ring-0"
            />
          </div>

          <div class="flex items-center justify-between gap-3">
            <label class="inline-flex items-center gap-2 text-sm text-dim">
              <input
                type="checkbox"
                name={@form[:remember_me].name}
                id="user_remember_me"
                value="true"
                class="h-4 w-4 rounded border-line bg-muted text-primary focus:ring-0"
              /> Keep me logged in
            </label>

            <.link
              href={~p"/users/reset_password"}
              class="text-sm text-dim transition hover:text-foreground"
            >
              Forgot password?
            </.link>
          </div>

          <button
            type="submit"
            phx-disable-with="Logging in..."
            class="w-full rounded-md bg-primary py-2.5 text-sm font-semibold text-primary-foreground transition hover:opacity-90"
          >
            Log in
          </button>
        </.form>

        <div class="mt-8 border-t border-line pt-6">
          <p class="text-center text-sm text-dim">Want to explore first?</p>
          <form action={~p"/demo"} method="post" class="mt-3 space-y-3">
            <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />
            <input
              type="email"
              name="email"
              placeholder="Email for instant demo access"
              required
              aria-label="Email for demo access"
              class="w-full rounded-md border-line bg-muted px-3 py-2.5 text-sm text-foreground placeholder:text-faint focus:border-primary focus:ring-0"
            />
            <button
              type="submit"
              class="w-full rounded-md border border-line py-2.5 text-sm font-medium text-dim transition hover:border-primary hover:text-primary"
            >
              Try demo
            </button>
          </form>
          <p class="mt-3 text-center text-xs text-faint">
            Sample clients, programmes &amp; workouts included
          </p>
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
