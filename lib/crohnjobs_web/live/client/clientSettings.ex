defmodule CrohnjobsWeb.Client.ClientSettings do
  use CrohnjobsWeb, :live_view
  alias Crohnjobs.Clients
  alias Crohnjobs.Clients.Client
  alias Crohnjobs.Repo

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    client = Repo.get_by(Client, %{user_id: user.id})

    {:ok,
     socket
     |> assign(:client, client)
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

          <%= if @client.age do %>
            <div>
              <label class="block text-sm font-medium text-gray-700">Age</label>
              <p class="mt-1 text-gray-900"><%= @client.age %> years</p>
            </div>
          <% end %>

          <%= if @client.height do %>
            <div>
              <label class="block text-sm font-medium text-gray-700">Height</label>
              <p class="mt-1 text-gray-900"><%= @client.height %> cm</p>
            </div>
          <% end %>

          <%= if @client.sex do %>
            <div>
              <label class="block text-sm font-medium text-gray-700">Sex</label>
              <p class="mt-1 text-gray-900"><%= @client.sex %></p>
            </div>
          <% end %>
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
