# ScopeStrength - personal trainer management application
# Copyright (C) 2026  Ebrahim Shahid Arshad
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# SPDX-License-Identifier: AGPL-3.0-or-later

defmodule ScopestrengthWeb.UserRegistrationLive do
alias Scopestrength.Clients
  use ScopestrengthWeb, :live_view

  alias Scopestrength.Account
  alias Scopestrength.Account.User
  alias Scopestrength.Trainers
  alias Scopestrength.Invites

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-md mt-12">
      <div class="bg-card rounded-2xl p-6 shadow ring-1 ring-black/5">
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
            options={[{"Client","client"},{"Trainer","trainer"}]}
            label="I am a"
            type="select"
            field={@form[:role]}
            phx-change="role_changed"
          />

          <div :if={@selected_role == "client"}>
            <label for="user_invite_code" class="block text-sm font-semibold leading-6 text-foreground">
              Invite Code <span class="font-normal text-dim">(optional)</span>
            </label>
            <input
              type="text"
              name="user[invite_code]"
              id="user_invite_code"
              value={@invite_code}
              class="mt-2 block w-full rounded-lg text-foreground focus:ring-0 sm:text-sm sm:leading-6 phx-no-feedback:border-line phx-no-feedback:focus:border-zinc-400 border-line focus:border-zinc-400"
              placeholder="Have a code from your coach? Enter it here"
              phx-blur="validate_invite_code"
            />

            <div :if={@invite_status == :valid} class="mt-1 text-sm text-primary flex items-center gap-1">
              <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
              </svg>
              <span>Valid invite from trainer: <%= @trainer_name %></span>
            </div>

            <div :if={@invite_status == :invalid} class="mt-1 text-sm text-danger flex items-center gap-1">
              <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"/>
              </svg>
              <span>Invalid or expired invite code</span>
            </div>

            <div :if={@invite_status == :already_used} class="mt-1 text-sm text-danger flex items-center gap-1">
              <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"/>
              </svg>
              <span>This invite code has already been used</span>
            </div>

            <div :if={@invite_status == :email_mismatch} class="mt-1 text-sm text-danger flex items-center gap-1">
              <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"/>
              </svg>
              <span>This invite was sent to a different email address</span>
            </div>
          </div>

          <p class="text-sm text-dim mt-2">By creating an account you agree to our <.link href="#" class="underline">terms</.link> and <.link href="#" class="underline">privacy policy</.link>.</p>

          <:actions>
            <.button phx-disable-with="Creating account..." class="w-full">Create an account</.button>
          </:actions>
        </.simple_form>
      </div>

      <p class="text-center text-sm mt-4 text-dim">
        Or <.link navigate={~p"/users/log_in"} class="font-semibold hover:underline">Log in Instead</.link>
      </p>
    </div>
    """
  end

  def mount(params, _session, socket) do
    changeset = Account.change_user_registration(%User{})

    invite_code = params["invite"]

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false)
      |> assign(selected_role: "client")
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
    case validate_client_invite(user_params) do
      {:error, message} ->
        {:noreply, put_flash(socket, :error, message)}

      {:ok, trainer_id} ->
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

              "client" ->
                {:ok, client} = Clients.create_client(%{user_id: user.id})

                if trainer_id do
                  Invites.link_client_to_trainer(client.id, trainer_id)
                end
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

  defp validate_client_invite(%{"role" => "client"}) do
    {:ok, nil}
  end

  defp validate_client_invite(%{"role" => "trainer"}) do
    {:ok, nil}
  end

  defp validate_client_invite(_params) do
    {:ok, nil}
  end

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
