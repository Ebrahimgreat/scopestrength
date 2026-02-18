defmodule CrohnjobsWeb.UserRegistrationLive do
alias Crohnjobs.Subscriptions
alias Crohnjobs.Clients
  use CrohnjobsWeb, :live_view

  alias Crohnjobs.Account
  alias Crohnjobs.Account.User
  alias Crohnjobs.Trainers
  alias Crohnjobs.Invites

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-md mt-12">
      <div class="bg-white rounded-2xl p-6 shadow ring-1 ring-black/5">
        <.header class="text-center">
          Register for an account
          <:subtitle>
            Already registered?
            <.link navigate={~p"/users/log_in"} class="font-semibold text-brand hover:underline">
              Log in
            </.link>
            to your account now.
          </:subtitle>
        </.header>

        <.simple_form
          for={@form}
          id="registration_form"
          phx-submit="save"
          phx-change="validate"
          phx-trigger-action={@trigger_submit}
          action={~p"/users/log_in?_action=registered"}
          method="post"
        >
          <.error :if={@check_errors}>
            Oops, something went wrong! Please check the errors below.
          </.error>

          <.input field={@form[:name]} type="text" label="Full name" required/>
          <.input field={@form[:email]} type="email" label="Email" required />
          <.input field={@form[:password]} type="password" label="Password" required />
          <.input
            options={[{"Trainer","trainer"},{"Client","client"}]}
            label="I am a"
            type="select"
            field={@form[:role]}
            phx-change="role_changed"
          />

          <!-- Invite Code Field (only for clients) -->
          <div :if={@selected_role == "client"}>
            <label for="user_invite_code" class="block text-sm font-semibold leading-6 text-zinc-800">
              Invite Code
            </label>
            <input
              type="text"
              name="user[invite_code]"
              id="user_invite_code"
              value={@invite_code}
              class="mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6 phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400 border-zinc-300 focus:border-zinc-400"
              placeholder="Enter the code from your trainer"
              required
              phx-blur="validate_invite_code"
            />

            <!-- Invite validation feedback -->
            <div :if={@invite_status == :valid} class="mt-1 text-sm text-green-600 flex items-center gap-1">
              <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
              </svg>
              <span>Valid invite from trainer: <%= @trainer_name %></span>
            </div>

            <div :if={@invite_status == :invalid} class="mt-1 text-sm text-red-600 flex items-center gap-1">
              <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"/>
              </svg>
              <span>Invalid or expired invite code</span>
            </div>

            <div :if={@invite_status == :already_used} class="mt-1 text-sm text-red-600 flex items-center gap-1">
              <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"/>
              </svg>
              <span>This invite code has already been used</span>
            </div>

            <div :if={@invite_status == :email_mismatch} class="mt-1 text-sm text-red-600 flex items-center gap-1">
              <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"/>
              </svg>
              <span>This invite was sent to a different email address</span>
            </div>
          </div>

          <p class="text-sm text-zinc-500 mt-2">By creating an account you agree to our <.link href="#" class="underline">terms</.link> and <.link href="#" class="underline">privacy policy</.link>.</p>

          <:actions>
            <.button phx-disable-with="Creating account..." class="w-full">Create an account</.button>
          </:actions>
        </.simple_form>
      </div>

      <p class="text-center text-sm mt-4 text-zinc-500">
        Or <.link navigate={~p"/users/log_in"} class="font-semibold hover:underline">Log in Instead</.link>
      </p>
    </div>
    """
  end

  def mount(params, _session, socket) do
    changeset = Account.change_user_registration(%User{})

    # Get invite code from URL params if present
    invite_code = params["invite"]

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false)
      |> assign(selected_role: "trainer")
      |> assign(invite_code: invite_code)
      |> assign(invite_status: nil)
      |> assign(trainer_name: nil)
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event("role_changed", %{"user" => %{"role" => role}}, socket) do
    {:noreply, assign(socket, selected_role: role, invite_status: nil)}
  end

  def handle_event("validate_invite_code", %{"user" => %{"invite_code" => code, "email" => email}}, socket) when code != "" and email != "" do
    case validate_invite(code, email) do
      {:ok, trainer_name} ->
        {:noreply, assign(socket, invite_status: :valid, trainer_name: trainer_name)}

      {:error, reason} ->
        {:noreply, assign(socket, invite_status: reason, trainer_name: nil)}
    end
  end

  def handle_event("validate_invite_code", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    # Validate invite code for clients BEFORE registration
    case validate_client_invite(user_params) do
      {:error, message} ->
        {:noreply, put_flash(socket, :error, message)}

      {:ok, trainer_id} ->
        # Proceed with registration
        user_params = Map.put(user_params, "type", "normal")
        case Account.register_user(user_params) do
          {:ok, user} ->
            {:ok, _} =
              Account.deliver_user_confirmation_instructions(
                user,
                &url(~p"/users/confirm/#{&1}")
              )

            changeset = Account.change_user_registration(user)

            case user.role do
              "trainer" ->
                Trainers.create_trainer(%{user_id: user.id})
                now = DateTime.utc_now()
                trial_days = 7

                Subscriptions.create_subscription(%{
                  user_id: user.id,
                  name: "Basic",
                  plan: "trial",
                  trial_start: now,
                  trial_end: DateTime.add(now, trial_days * 86_400, :second),
                  paid_until: nil
                })

              "client" ->
                # Create client and link to trainer
                {:ok, client} = Clients.create_client(%{user_id: user.id})
                # Link client to trainer from invite
                Invites.link_client_to_trainer(client.id, trainer_id)
            end

            {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
        end
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Account.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end

  # Validates invite code for client registration
  defp validate_client_invite(%{"role" => "client", "invite_code" => code, "email" => email})
       when code != "" and email != "" do
    case Invites.redeem_invite(code, email) do
      {:ok, trainer_id} ->
        {:ok, trainer_id}

      {:error, :invalid_code} ->
        {:error, "Invalid invite code. Please check with your trainer."}

      {:error, :already_used} ->
        {:error, "This invite code has already been used."}

      {:error, :email_mismatch} ->
        {:error, "This invite code was sent to a different email address."}

      {:error, _} ->
        {:error, "Unable to validate invite code. Please try again."}
    end
  end

  # Client must have invite code
  defp validate_client_invite(%{"role" => "client"}) do
    {:error, "Clients must register with an invite code from their trainer."}
  end

  # Trainers don't need invite code
  defp validate_client_invite(%{"role" => "trainer"}) do
    {:ok, nil}
  end

  # Default case
  defp validate_client_invite(_params) do
    {:ok, nil}
  end

  # Validates invite without redeeming (for real-time feedback)
  defp validate_invite(code, email) when code != "" and email != "" do
    case Invites.check_invite(code, email) do
      {:ok, _trainer_id, trainer_name} ->
        {:ok, trainer_name}

      {:error, reason} ->
        {:error, reason}
    end
  rescue
    _ -> {:error, :invalid}
  end

  defp validate_invite(_code, _email), do: {:error, :invalid}
end
