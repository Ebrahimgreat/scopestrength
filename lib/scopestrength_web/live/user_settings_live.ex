defmodule ScopestrengthWeb.UserSettingsLive do
  use ScopestrengthWeb, :live_view

  alias Scopestrength.Account
  alias Scopestrength.Trainers
  alias Scopestrength.Repo

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Account.update_user_email(socket.assigns.current_user, token) do
        :ok -> put_flash(socket, :info, "Email changed successfully.")
        :error -> put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/trainer/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    trainer = Trainers.get_trainer_byUserId(user.id) |> Repo.preload(:certifications)
    email_changeset = Account.change_user_email(user)
    password_changeset = Account.change_user_password(user)
    trainer_changeset = Trainers.change_trainer(trainer)
    cert_changeset = Trainers.change_certification(%Scopestrength.Trainers.Certification{})

    socket =
      socket
      |> assign(:trainer, trainer)
      |> assign(:trainer_form, to_form(trainer_changeset, as: "trainer"))
      |> assign(:certifications, trainer.certifications)
      |> assign(:cert_form, to_form(cert_changeset, as: "cert"))
      |> assign(:show_cert_form, false)
      |> assign(:name, user.name)
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)
      |> assign(:uploaded_files, [])
      |> allow_upload(:profile_picture,
        accept: ~w(.jpg .jpeg .png .gif),
        max_entries: 1,
        max_file_size: 5_000_000
      )

    {:ok, socket}
  end

  # --- Profile Picture ---

  def handle_event("validate", _params, socket), do: {:noreply, socket}

  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :profile_picture, ref)}
  end

  def handle_event("save_profile_picture", _params, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :profile_picture, fn %{path: path}, entry ->
        upload_dir = Path.join(["priv", "static", "uploads"])
        File.mkdir_p!(upload_dir)
        filename = "#{entry.uuid}.#{ext(entry)}"
        dest = Path.join([upload_dir, filename])
        File.cp!(path, dest)
        {:ok, "/uploads/#{filename}"}
      end)

    case uploaded_files do
      [url | _] ->
        {:ok, updated_trainer} = Trainers.update_trainer(socket.assigns.trainer, %{profile_picture_url: url})
        {:noreply, socket |> assign(:trainer, updated_trainer) |> put_flash(:info, "Profile picture updated!")}

      [] ->
        {:noreply, put_flash(socket, :error, "No file was uploaded")}
    end
  end

  def handle_event("remove_profile_picture", _params, socket) do
    trainer = socket.assigns.trainer

    if trainer.profile_picture_url do
      file_path = Path.join("priv/static", trainer.profile_picture_url)
      File.rm(file_path)
    end

    {:ok, updated_trainer} = Trainers.update_trainer(trainer, %{profile_picture_url: nil})
    {:noreply, socket |> assign(:trainer, updated_trainer) |> put_flash(:info, "Profile picture removed")}
  end

  # --- Trainer Profile ---

  def handle_event("validate_trainer", %{"trainer" => params}, socket) do
    changeset =
      socket.assigns.trainer
      |> Trainers.change_trainer(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :trainer_form, to_form(changeset, as: "trainer"))}
  end

  def handle_event("save_trainer", %{"trainer" => params}, socket) do
    case Trainers.update_trainer(socket.assigns.trainer, params) do
      {:ok, updated_trainer} ->
        {:noreply,
         socket
         |> assign(:trainer, updated_trainer)
         |> assign(:trainer_form, Trainers.change_trainer(updated_trainer) |> to_form(as: "trainer"))
         |> put_flash(:info, "Profile updated successfully")}

      {:error, changeset} ->
        {:noreply, assign(socket, :trainer_form, to_form(changeset, as: "trainer"))}
    end
  end

  # --- Certifications ---

  def handle_event("show_cert_form", _params, socket) do
    {:noreply, assign(socket, :show_cert_form, true)}
  end

  def handle_event("hide_cert_form", _params, socket) do
    cert_changeset = Trainers.change_certification(%Scopestrength.Trainers.Certification{})
    {:noreply, socket |> assign(:show_cert_form, false) |> assign(:cert_form, to_form(cert_changeset, as: "cert"))}
  end

  def handle_event("save_cert", %{"cert" => params}, socket) do
    params = Map.put(params, "trainer_id", socket.assigns.trainer.id)

    case Trainers.create_certification(params) do
      {:ok, _cert} ->
        trainer = Trainers.get_trainer_byUserId(socket.assigns.current_user.id) |> Repo.preload(:certifications)
        cert_changeset = Trainers.change_certification(%Scopestrength.Trainers.Certification{})

        {:noreply,
         socket
         |> assign(:trainer, trainer)
         |> assign(:certifications, trainer.certifications)
         |> assign(:cert_form, to_form(cert_changeset, as: "cert"))
         |> assign(:show_cert_form, false)
         |> put_flash(:info, "Certification added")}

      {:error, changeset} ->
        {:noreply, assign(socket, :cert_form, to_form(changeset, as: "cert"))}
    end
  end

  def handle_event("delete_cert", %{"id" => id}, socket) do
    cert = Trainers.get_certification!(id)
    {:ok, _} = Trainers.delete_certification(cert)

    trainer = Trainers.get_trainer_byUserId(socket.assigns.current_user.id) |> Repo.preload(:certifications)

    {:noreply,
     socket
     |> assign(:trainer, trainer)
     |> assign(:certifications, trainer.certifications)
     |> put_flash(:info, "Certification removed")}
  end

  # --- Account / Security ---

  def handle_event("update_name", %{"name" => name}, socket) do
    user = socket.assigns.current_user

    case Account.update_name(user, %{"name" => name}) do
      {:ok, user} ->
        {:noreply, socket |> put_flash(:info, "Name updated") |> assign(:name, user.name)}

      {:error, changeset} ->
        {:noreply, assign(socket, :name_form, to_form(changeset))}
    end
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

  # --- Helpers ---

  defp get_initials(trainer) do
    case Repo.preload(trainer, :user) do
      %{user: %{name: name}} when not is_nil(name) ->
        name
        |> String.split(" ")
        |> Enum.take(2)
        |> Enum.map(&String.first/1)
        |> Enum.join("")
        |> String.upcase()

      _ ->
        "?"
    end
  end

  defp ext(entry) do
    [ext | _] = MIME.extensions(entry.client_type)
    ext
  end

  defp error_to_string(:too_large), do: "File is too large (max 5MB)"
  defp error_to_string(:not_accepted), do: "File type not accepted (only JPG, PNG, GIF)"
  defp error_to_string(:too_many_files), do: "You can only upload one file"
  defp error_to_string(_), do: "Something went wrong"

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto px-4 py-6">
      <h1 class="text-3xl font-bold text-gray-900 mb-8">Profile Settings</h1>

      <!-- Demo Account Notice -->
      <div :if={@current_user.type == "demo"} class="mb-6 p-4 bg-amber-50 border border-amber-200 rounded-lg">
        <div class="flex items-start gap-3">
          <svg class="w-5 h-5 text-amber-600 flex-shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd"/>
          </svg>
          <div>
            <h3 class="text-sm font-semibold text-amber-900">Demo Account</h3>
            <p class="mt-1 text-sm text-amber-700">Settings are view-only in demo mode. Upgrade to a full account to make changes.</p>
          </div>
        </div>
      </div>

      <!-- Profile Picture -->
      <div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden mb-6">
        <div class="px-6 py-4 border-b border-gray-100">
          <h2 class="text-xl font-semibold text-gray-900">Profile Picture</h2>
          <p class="text-sm text-gray-500 mt-1">Upload a photo to personalize your public profile</p>
        </div>
        <div class="p-6">
          <div class="flex flex-col md:flex-row gap-6 items-start">
            <div class="flex-shrink-0">
              <%= if @trainer.profile_picture_url do %>
                <div class="relative group">
                  <img
                    src={@trainer.profile_picture_url}
                    alt="Profile picture"
                    class="w-32 h-32 rounded-full object-cover border-4 border-emerald-100"
                  />
                  <button
                    phx-click="remove_profile_picture"
                    data-confirm="Remove your profile picture?"
                    class="absolute top-0 right-0 bg-red-500 hover:bg-red-600 text-white rounded-full p-2 opacity-0 group-hover:opacity-100 transition-opacity"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                    </svg>
                  </button>
                </div>
              <% else %>
                <div class="w-32 h-32 rounded-full bg-gradient-to-br from-emerald-400 to-teal-500 flex items-center justify-center text-white text-4xl font-bold border-4 border-emerald-100">
                  <%= get_initials(@trainer) %>
                </div>
              <% end %>
            </div>

            <div class="flex-1">
              <form phx-submit="save_profile_picture" phx-change="validate" class="space-y-4">
                <div class="border-2 border-dashed border-gray-300 rounded-lg p-6 hover:border-emerald-400 transition-colors">
                  <div class="text-center">
                    <svg class="mx-auto h-12 w-12 text-gray-400" stroke="currentColor" fill="none" viewBox="0 0 48 48">
                      <path d="M28 8H12a4 4 0 00-4 4v20m32-12v8m0 0v8a4 4 0 01-4 4H12a4 4 0 01-4-4v-4m32-4l-3.172-3.172a4 4 0 00-5.656 0L28 28M8 32l9.172-9.172a4 4 0 015.656 0L28 28m0 0l4 4m4-24h8m-4-4v8m-12 4h.02" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                    </svg>
                    <div class="mt-4">
                      <label class="cursor-pointer">
                        <span class="mt-2 block text-sm font-medium text-gray-900">Click to upload or drag and drop</span>
                        <span class="mt-1 block text-xs text-gray-500">PNG, JPG, GIF up to 5MB</span>
                        <.live_file_input upload={@uploads.profile_picture} class="sr-only" />
                      </label>
                    </div>
                  </div>

                  <%= for entry <- @uploads.profile_picture.entries do %>
                    <div class="mt-4">
                      <div class="flex items-center justify-between text-sm">
                        <span class="text-gray-700"><%= entry.client_name %></span>
                        <button type="button" phx-click="cancel_upload" phx-value-ref={entry.ref} class="text-red-600 hover:text-red-800">Cancel</button>
                      </div>
                      <div class="mt-2 w-full bg-gray-200 rounded-full h-2">
                        <div class="bg-emerald-600 h-2 rounded-full transition-all" style={"width: #{entry.progress}%"}></div>
                      </div>
                      <%= for err <- upload_errors(@uploads.profile_picture, entry) do %>
                        <p class="mt-2 text-sm text-red-600"><%= error_to_string(err) %></p>
                      <% end %>
                    </div>
                  <% end %>
                </div>

                <%= if length(@uploads.profile_picture.entries) > 0 do %>
                  <.button type="submit" class="w-full bg-emerald-600 hover:bg-emerald-700 text-white font-semibold py-3 rounded-lg transition-colors">
                    Upload Profile Picture
                  </.button>
                <% end %>
              </form>
              <%= for err <- upload_errors(@uploads.profile_picture) do %>
                <p class="mt-2 text-sm text-red-600"><%= error_to_string(err) %></p>
              <% end %>
            </div>
          </div>
        </div>
      </div>

      <!-- Trainer Profile Info -->
      <div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden mb-6">
        <div class="px-6 py-4 border-b border-gray-100">
          <h2 class="text-xl font-semibold text-gray-900">Trainer Profile</h2>
          <p class="text-sm text-gray-500 mt-1">This information is shown on your public profile</p>
        </div>
        <div class="p-6">
          <.simple_form
            for={@trainer_form}
            id="trainer_form"
            phx-submit="save_trainer"
            phx-change="validate_trainer"
          >
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div class="md:col-span-2">
                <.input
                  field={@trainer_form[:bio]}
                  type="textarea"
                  label="Bio"
                  placeholder="Tell clients about yourself..."
                  disabled={@current_user.type == "demo"}
                />
              </div>

              <.input
                field={@trainer_form[:specialization]}
                type="text"
                label="Specialization"
                placeholder="e.g. Strength & Conditioning"
                disabled={@current_user.type == "demo"}
              />

              <.input
                field={@trainer_form[:years_experience]}
                type="number"
                min="0"
                label="Years of Experience"
                placeholder="e.g. 5"
                disabled={@current_user.type == "demo"}
              />

              <.input
                field={@trainer_form[:location]}
                type="text"
                label="Location"
                placeholder="e.g. London, UK"
                disabled={@current_user.type == "demo"}
              />

              <.input
                field={@trainer_form[:style]}
                type="text"
                label="Training Style"
                placeholder="e.g. High Intensity, Functional"
                disabled={@current_user.type == "demo"}
              />

              <.input
                field={@trainer_form[:format]}
                type="select"
                label="Training Format"
                prompt="Select format"
                options={["In-Person", "Online", "Hybrid"]}
                disabled={@current_user.type == "demo"}
              />

              <.input
                field={@trainer_form[:instagram_url]}
                type="text"
                label="Instagram URL"
                placeholder="https://instagram.com/yourhandle"
                disabled={@current_user.type == "demo"}
              />
            </div>

            <div class="mt-4">
              <h3 class="text-base font-semibold text-gray-800 mb-3">Pricing</h3>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <.input
                  field={@trainer_form[:price_per_session]}
                  type="number"
                  min="0"
                  step="0.01"
                  label="Price per Session (£)"
                  placeholder="e.g. 50.00"
                  disabled={@current_user.type == "demo"}
                />
                <.input
                  field={@trainer_form[:price_per_month]}
                  type="number"
                  min="0"
                  step="0.01"
                  label="Price per Month (£)"
                  placeholder="e.g. 150.00"
                  disabled={@current_user.type == "demo"}
                />
              </div>
            </div>

            <div class="mt-4">
              <h3 class="text-base font-semibold text-gray-800 mb-3">Visibility</h3>
              <div class="space-y-3">
                <div class="flex items-center gap-3">
                  <.input
                    field={@trainer_form[:is_public]}
                    type="checkbox"
                    label="List me in the public marketplace"
                    disabled={@current_user.type == "demo"}
                  />
                </div>
                <div class="flex items-center gap-3">
                  <.input
                    field={@trainer_form[:availability]}
                    type="checkbox"
                    label="I am currently accepting new clients"
                    disabled={@current_user.type == "demo"}
                  />
                </div>
              </div>
            </div>

            <:actions>
              <.button class="bg-emerald-600 hover:bg-emerald-700 text-white" disabled={@current_user.type == "demo"}>
                Save Profile
              </.button>
            </:actions>
          </.simple_form>
        </div>
      </div>

      <!-- Certifications -->
      <div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden mb-6">
        <div class="px-6 py-4 border-b border-gray-100 flex items-center justify-between">
          <div>
            <h2 class="text-xl font-semibold text-gray-900">Certifications</h2>
            <p class="text-sm text-gray-500 mt-1">Add your professional certifications to build trust with clients</p>
          </div>
          <button
            :if={!@show_cert_form && @current_user.type != "demo"}
            phx-click="show_cert_form"
            class="bg-emerald-600 hover:bg-emerald-700 text-white text-sm font-medium px-4 py-2 rounded-lg transition-colors"
          >
            + Add Certification
          </button>
        </div>

        <div class="p-6">
          <!-- Certification Form -->
          <%= if @show_cert_form do %>
            <div class="bg-gray-50 rounded-lg p-4 mb-4 border border-gray-200">
              <h3 class="text-base font-semibold text-gray-800 mb-3">New Certification</h3>
              <.simple_form for={@cert_form} id="cert_form" phx-submit="save_cert">
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <.input field={@cert_form[:name]} type="text" label="Certification Name" placeholder="e.g. NASM CPT" required />
                  <.input field={@cert_form[:issuing_body]} type="text" label="Issuing Organisation" placeholder="e.g. NASM" />
                  <.input field={@cert_form[:issued_at]} type="date" label="Issue Date" />
                  <.input field={@cert_form[:expires_at]} type="date" label="Expiry Date" />
                </div>
                <:actions>
                  <div class="flex gap-3">
                    <.button class="bg-emerald-600 hover:bg-emerald-700 text-white">Save</.button>
                    <button type="button" phx-click="hide_cert_form" class="text-gray-600 hover:text-gray-800 text-sm font-medium px-4 py-2 rounded-lg border border-gray-300">
                      Cancel
                    </button>
                  </div>
                </:actions>
              </.simple_form>
            </div>
          <% end %>

          <!-- Certifications List -->
          <%= if Enum.empty?(@certifications) do %>
            <p class="text-gray-400 text-sm text-center py-4">No certifications added yet.</p>
          <% else %>
            <ul class="divide-y divide-gray-100">
              <%= for cert <- @certifications do %>
                <li class="py-3 flex items-start justify-between gap-4">
                  <div>
                    <p class="text-sm font-semibold text-gray-900"><%= cert.name %></p>
                    <%= if cert.issuing_body do %>
                      <p class="text-xs text-gray-500"><%= cert.issuing_body %></p>
                    <% end %>
                    <div class="flex gap-3 mt-1 text-xs text-gray-400">
                      <%= if cert.issued_at do %>
                        <span>Issued: <%= Calendar.strftime(cert.issued_at, "%b %Y") %></span>
                      <% end %>
                      <%= if cert.expires_at do %>
                        <span>Expires: <%= Calendar.strftime(cert.expires_at, "%b %Y") %></span>
                      <% end %>
                    </div>
                  </div>
                  <button
                    :if={@current_user.type != "demo"}
                    phx-click="delete_cert"
                    phx-value-id={cert.id}
                    data-confirm="Remove this certification?"
                    class="text-red-500 hover:text-red-700 text-xs flex-shrink-0"
                  >
                    Remove
                  </button>
                </li>
              <% end %>
            </ul>
          <% end %>
        </div>
      </div>

      <!-- Login & Security -->
      <div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
        <div class="px-6 py-4 border-b border-gray-100">
          <h2 class="text-xl font-semibold text-gray-900">Login & Security</h2>
        </div>
        <div class="p-6 space-y-8">
          <!-- Name -->
          <div>
            <h3 class="text-base font-semibold text-gray-800 mb-3">Display Name</h3>
            <.form id="name_form" phx-submit="update_name" class="space-y-4">
              <.input type="text" name="name" label="Name" value={@name} disabled={@current_user.type == "demo"} />
              <.button class="bg-emerald-600 hover:bg-emerald-700 text-white" disabled={@current_user.type == "demo"}>
                Update Name
              </.button>
            </.form>
          </div>

          <!-- Email -->
          <div>
            <h3 class="text-base font-semibold text-gray-800 mb-3">Email</h3>
            <.simple_form for={@email_form} id="email_form" phx-submit="update_email" phx-change="validate_email">
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

          <!-- Password -->
          <div>
            <h3 class="text-base font-semibold text-gray-800 mb-3">Password</h3>
            <.simple_form
              for={@password_form}
              id="password_form"
              action={~p"/users/log_in?_action=password_updated"}
              method="post"
              phx-change="validate_password"
              phx-submit="update_password"
              phx-trigger-action={@trigger_submit}
            >
              <input name={@password_form[:email].name} type="hidden" id="hidden_user_email" value={@current_email} />
              <.input field={@password_form[:password]} type="password" label="New password" required disabled={@current_user.type == "demo"} />
              <.input field={@password_form[:password_confirmation]} type="password" label="Confirm new password" disabled={@current_user.type == "demo"} />
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
      </div>
    </div>
    """
  end
end
