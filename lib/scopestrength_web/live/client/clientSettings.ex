defmodule ScopestrengthWeb.Client.ClientSettings do
  use ScopestrengthWeb, :live_view
  alias Scopestrength.Clients
  alias Scopestrength.Clients.Client
  alias Scopestrength.Account
  alias Scopestrength.Repo

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    client = Repo.get_by(Client, %{user_id: user.id})
    client_form = client |> Clients.change_client() |> to_form(as: "client")
    email_changeset = Account.change_user_email(user)
    password_changeset = Account.change_user_password(user)

    {:ok,
     socket
     |> assign(:client, client)
     |> assign(:client_form, client_form)
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
     )}
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :profile_picture, ref)}
  end

  def handle_event("save_profile_picture", _params, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :profile_picture, fn %{path: path}, entry ->
        # Ensure upload directory exists
        upload_dir = Path.join(["priv", "static", "uploads"])
        File.mkdir_p!(upload_dir)

        # Generate filename and destination path
        filename = "#{entry.uuid}.#{ext(entry)}"
        dest = Path.join([upload_dir, filename])

        # Copy file to destination
        File.cp!(path, dest)

        # Return URL path
        {:ok, "/uploads/#{filename}"}
      end)

    case uploaded_files do
      [url | _] ->
        client = socket.assigns.client
        {:ok, updated_client} = Clients.update_client(client, %{profile_picture_url: url})

        {:noreply,
         socket
         |> assign(:client, updated_client)
         |> put_flash(:info, "Profile picture updated successfully!")}

      [] ->
        {:noreply, socket |> put_flash(:error, "No file was uploaded")}
    end
  end

  def handle_event("validate_client", %{"client" => client_params}, socket) do
    changeset =
      socket.assigns.client
      |> Clients.change_client(client_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :client_form, to_form(changeset, as: "client"))}
  end

  def handle_event("save_client", %{"client" => client_params}, socket) do
    client = socket.assigns.client

    case Clients.update_client(client, client_params) do
      {:ok, updated_client} ->
        {:noreply,
         socket
         |> assign(:client, updated_client)
         |> assign(:client_form, Clients.change_client(updated_client) |> to_form(as: "client"))
         |> put_flash(:info, "Client settings updated")}

      {:error, changeset} ->
        {:noreply, assign(socket, :client_form, to_form(changeset, as: "client"))}
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

  def handle_event("update_name", %{"name" => name}, socket) do
    user = socket.assigns.current_user

    case Account.update_name(user, %{"name" => name}) do
      {:ok, user} ->
        {:noreply, socket |> put_flash(:info, "Name updated") |> assign(:name, user.name)}

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

  def handle_event("remove_profile_picture", _params, socket) do
    client = socket.assigns.client

    # Delete the file if it exists
    if client.profile_picture_url do
      file_path = Path.join("priv/static", client.profile_picture_url)
      File.rm(file_path)
    end

    {:ok, updated_client} = Clients.update_client(client, %{profile_picture_url: nil})

    {:noreply,
     socket
     |> assign(:client, updated_client)
     |> put_flash(:info, "Profile picture removed")}
  end

  defp ext(entry) do
    [ext | _] = MIME.extensions(entry.client_type)
    ext
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto px-4 py-6">
      <div class="mb-6">
        <.link navigate={~p"/client"} class="text-emerald-600 hover:text-emerald-700 flex items-center gap-2">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"></path>
          </svg>
          Back to Dashboard
        </.link>
      </div>

      <h1 class="text-3xl font-bold text-gray-900 mb-8">Profile Settings</h1>

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

      <!-- Profile Picture Section -->
      <div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden mb-6">
        <div class="px-6 py-4 border-b border-gray-100">
          <h2 class="text-xl font-semibold text-gray-900">Profile Picture</h2>
          <p class="text-sm text-gray-500 mt-1">Upload a profile picture to personalize your account</p>
        </div>

        <div class="p-6">
          <div class="flex flex-col md:flex-row gap-6 items-start">
            <!-- Current Profile Picture -->
            <div class="flex-shrink-0">
              <%= if @client.profile_picture_url do %>
                <div class="relative group">
                  <img
                    src={@client.profile_picture_url}
                    alt="Profile picture"
                    class="w-32 h-32 rounded-full object-cover border-4 border-emerald-100"
                  />
                  <button
                    phx-click="remove_profile_picture"
                    data-confirm="Are you sure you want to remove your profile picture?"
                    class="absolute top-0 right-0 bg-red-500 hover:bg-red-600 text-white rounded-full p-2 opacity-0 group-hover:opacity-100 transition-opacity"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                    </svg>
                  </button>
                </div>
              <% else %>
                <div class="w-32 h-32 rounded-full bg-gradient-to-br from-emerald-400 to-teal-500 flex items-center justify-center text-white text-4xl font-bold border-4 border-emerald-100">
                  <%= get_initials(@client) %>
                </div>
              <% end %>
            </div>

            <!-- Upload Form -->
            <div class="flex-1">
              <form phx-submit="save_profile_picture" phx-change="validate" class="space-y-4">
                <div class="border-2 border-dashed border-gray-300 rounded-lg p-6 hover:border-emerald-400 transition-colors">
                  <div class="text-center">
                    <svg class="mx-auto h-12 w-12 text-gray-400" stroke="currentColor" fill="none" viewBox="0 0 48 48">
                      <path d="M28 8H12a4 4 0 00-4 4v20m32-12v8m0 0v8a4 4 0 01-4 4H12a4 4 0 01-4-4v-4m32-4l-3.172-3.172a4 4 0 00-5.656 0L28 28M8 32l9.172-9.172a4 4 0 015.656 0L28 28m0 0l4 4m4-24h8m-4-4v8m-12 4h.02" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"></path>
                    </svg>

                    <div class="mt-4">
                      <label class="cursor-pointer">
                        <span class="mt-2 block text-sm font-medium text-gray-900">
                          Click to upload or drag and drop
                        </span>
                        <span class="mt-1 block text-xs text-gray-500">
                          PNG, JPG, GIF up to 5MB
                        </span>
                        <.live_file_input upload={@uploads.profile_picture} class="sr-only" />
                      </label>
                    </div>
                  </div>

                  <!-- Upload Progress -->
                  <%= for entry <- @uploads.profile_picture.entries do %>
                    <div class="mt-4">
                      <div class="flex items-center justify-between text-sm">
                        <span class="text-gray-700"><%= entry.client_name %></span>
                        <button
                          type="button"
                          phx-click="cancel_upload"
                          phx-value-ref={entry.ref}
                          class="text-red-600 hover:text-red-800"
                        >
                          Cancel
                        </button>
                      </div>
                      <div class="mt-2 w-full bg-gray-200 rounded-full h-2">
                        <div
                          class="bg-emerald-600 h-2 rounded-full transition-all"
                          style={"width: #{entry.progress}%"}
                        >
                        </div>
                      </div>
                    </div>

                    <%= for err <- upload_errors(@uploads.profile_picture, entry) do %>
                      <p class="mt-2 text-sm text-red-600"><%= error_to_string(err) %></p>
                    <% end %>
                  <% end %>
                </div>

                <%= if length(@uploads.profile_picture.entries) > 0 do %>
                  <.button
                    type="submit"
                    class="w-full bg-emerald-600 hover:bg-emerald-700 text-white font-semibold py-3 rounded-lg transition-colors"
                  >
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

      <!-- Additional Settings Section -->
      <div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
        <div class="px-6 py-4 border-b border-gray-100">
          <h2 class="text-xl font-semibold text-gray-900">Account Information</h2>
        </div>

        <div class="p-6 space-y-4">
          <%= if client = Repo.preload(@client, :user) do %>
            <%= if client.user do %>
              <div>
                <label class="block text-sm font-medium text-gray-700">Email</label>
                <p class="mt-1 text-gray-900"><%= client.user.email %></p>
              </div>
            <% end %>
          <% end %>

          <form phx-change="validate_client" phx-submit="save_client" class="space-y-4">
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <.input
                field={@client_form[:age]}
                type="number"
                min="0"
                step="1"
                label="Age"
                placeholder="e.g. 28"
              />

              <.input
                field={@client_form[:height]}
                type="number"
                min="0"
                step="0.1"
                label="Height (cm)"
                placeholder="e.g. 180.5"
              />

              <.input
                field={@client_form[:sex]}
                type="select"
                label="Sex"
                prompt="Select"
                options={["male", "female", "other"]}
              />
            </div>

            <div>
              <.button class="bg-emerald-600 hover:bg-emerald-700 text-white">
                Save Changes
              </.button>
            </div>
          </form>
        </div>
      </div>

      <!-- Login & Security -->
      <div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden mt-6">
        <div class="px-6 py-4 border-b border-gray-100">
          <h2 class="text-xl font-semibold text-gray-900">Login & Security</h2>
        </div>

        <div class="p-6 space-y-8">
          <div>
            <h3 class="text-lg font-semibold text-gray-900 mb-3">Name</h3>
            <.form id="name_form" phx-submit="update_name" class="space-y-4">
              <.input type="text" name="name" label="Name" value={@name} disabled={@current_user.type == "demo"} />
              <.button class="bg-emerald-600 hover:bg-emerald-700 text-white" disabled={@current_user.type == "demo"}>
                Update Name
              </.button>
            </.form>
          </div>

          <div>
            <h3 class="text-lg font-semibold text-gray-900 mb-3">Email</h3>
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
            <h3 class="text-lg font-semibold text-gray-900 mb-3">Password</h3>
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

          <div>
            <h3 class="text-lg font-semibold text-gray-900 mb-3">Reset Password</h3>
            <p class="text-sm text-gray-600 mb-4">
              Forgot your password? Send a reset link to your email.
            </p>
            <.link navigate={~p"/users/reset_password"} class="text-emerald-600 hover:text-emerald-700">
              Send reset link
            </.link>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp get_initials(client) do
    case Repo.preload(client, :user) do
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

  defp error_to_string(:too_large), do: "File is too large (max 5MB)"
  defp error_to_string(:not_accepted), do: "File type not accepted (only JPG, PNG, GIF)"
  defp error_to_string(:too_many_files), do: "You can only upload one file"
  defp error_to_string(_), do: "Something went wrong"
end
