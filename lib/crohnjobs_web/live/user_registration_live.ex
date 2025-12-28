defmodule CrohnjobsWeb.UserRegistrationLive do
  use CrohnjobsWeb, :live_view

  alias Crohnjobs.Account
  alias Crohnjobs.Account.User
  alias Crohnjobs.Trainers

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

          <p class="text-sm text-zinc-500 mt-2">By creating an account you agree to our <.link href="#" class="underline">terms</.link> and <.link href="#" class="underline">privacy policy</.link>.</p>

          <:actions>
            <.button phx-disable-with="Creating account..." class="w-full">Create an account</.button>
          </:actions>
        </.simple_form>
      </div>

      <p class="text-center text-sm mt-4 text-zinc-500">
        Or <.link navigate={~p"/"} class="font-semibold hover:underline">Return home</.link>
      </p>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Account.change_user_registration(%User{})

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false)
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event("save", %{"user" => user_params}, socket) do

    case Account.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Account.deliver_user_confirmation_instructions(
            user,
            &url(~p"/users/confirm/#{&1}")
          )

        changeset = Account.change_user_registration(user)
        Trainers.create_trainer(%{user_id: user.id, bio: "Weight Lifting"})
        {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
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
end
