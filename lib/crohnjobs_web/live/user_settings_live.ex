defmodule CrohnjobsWeb.UserSettingsLive do
  use CrohnjobsWeb, :live_view

  alias Crohnjobs.Account

  def render(assigns) do
    ~H"""
    <.header class="text-center">
      Account Settings
      <:subtitle>Manage your account email address and password settings</:subtitle>
    </.header>

    <!-- Demo Account Notice -->
    <div :if={@current_user.type == "demo"} class="mb-6 p-4 bg-amber-50 border border-amber-200 rounded-lg">
      <div class="flex items-start gap-3">
        <svg class="w-5 h-5 text-amber-600 flex-shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
          <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd"/>
        </svg>
        <div>
          <h3 class="text-sm font-semibold text-amber-900">Demo Account</h3>
          <p class="mt-1 text-sm text-amber-700">Settings are view-only in demo mode. Upgrade to a full account to modify your email and password.</p>
        </div>
      </div>
    </div>

    <div class="space-y-12 divide-y">


         <.form

          id="name"
          phx-submit="update_name"
        >
       <.input type="text" name="name" value={@name} disabled={@current_user.type == "demo"}/>



<.button disabled={@current_user.type == "demo"}>
Update Name
</.button>
        </.form>


    <div>


    </div>




      <div>
        <.simple_form
          for={@email_form}
          id="email_form"
          phx-submit="update_email"
          phx-change="validate_email"
        >



          <.input field={@email_form[:email]} type="email" label="Email" required disabled={@current_user.type == "demo"} />
          <.input
            field={@email_form[:current_password]}
            name="current_password"
            id="current_password_for_email"
            type="password"
            label="Current password"
            value={@email_form_current_password}
            required
            disabled={@current_user.type == "demo"}
          />
          <:actions>
            <.button phx-disable-with="Changing..." disabled={@current_user.type == "demo"}>Change Email</.button>
          </:actions>
        </.simple_form>
      </div>
      <div>
        <.simple_form
          for={@password_form}
          id="password_form"
          action={~p"/users/log_in?_action=password_updated"}
          method="post"
          phx-change="validate_password"
          phx-submit="update_password"
          phx-trigger-action={@trigger_submit}
        >
          <input
            name={@password_form[:email].name}
            type="hidden"
            id="hidden_user_email"
            value={@current_email}
          />
          <.input field={@password_form[:password]} type="password" label="New password" required disabled={@current_user.type == "demo"} />
          <.input
            field={@password_form[:password_confirmation]}
            type="password"
            label="Confirm new password"
            disabled={@current_user.type == "demo"}
          />
          <.input
            field={@password_form[:current_password]}
            name="current_password"
            type="password"
            label="Current password"
            id="current_password_for_password"
            value={@current_password}
            required
            disabled={@current_user.type == "demo"}
          />
          <:actions>
            <.button phx-disable-with="Changing..." disabled={@current_user.type == "demo"}>Change Password</.button>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Account.update_user_email(socket.assigns.current_user, token) do
        :ok ->
          put_flash(socket, :info, "Email changed successfully.")

        :error ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    email_changeset = Account.change_user_email(user)
    password_changeset = Account.change_user_password(user)

    socket =
      socket
      |> assign(:name, user.name)
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    email_form =
      socket.assigns.current_user
      |> Account.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end



 def handle_event("update_name",%{"name"=> name}, socket) do
  user = socket.assigns.current_user
  case Account.update_name(user,%{"name"=> name}) do
    {:ok, user}->
      {:noreply, socket|> put_flash(:info,"Name updated")|> assign(:name, user.name)}
      {:error, changeset} ->
        {:noreply, assign(socket, :name_form, to_form(changeset))}
    end

 end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Account.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Account.deliver_user_update_email_instructions(
          applied_user,
          user.email,
          &url(~p"/users/settings/confirm_email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end





  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Account.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Account.update_user_password(user, password, user_params) do
      {:ok, user} ->
        password_form =
          user
          |> Account.change_user_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end
end
