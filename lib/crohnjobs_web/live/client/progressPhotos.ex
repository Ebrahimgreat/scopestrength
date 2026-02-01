defmodule CrohnjobsWeb.Client.ProgressPhotos do
  use CrohnjobsWeb, :live_view

  alias Crohnjobs.ProgressPhotos
  alias Crohnjobs.Clients.Client
  alias Crohnjobs.Notifications
  alias Crohnjobs.Repo

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    client = Repo.get_by(Client, %{user_id: user.id})
    photos = ProgressPhotos.list_progress_photos_for_client(client.id)

    {:ok,
     socket
     |> assign(:client, client)
     |> assign(:photos, photos)
     |> assign(:show_upload_form, false)
     |> allow_upload(:progress_photo,
       accept: ~w(.jpg .jpeg .png .gif),
       max_entries: 1,
       max_file_size: 5_000_000
     )}
  end

  def handle_event("toggle_upload_form", _params, socket) do
    {:noreply, assign(socket, :show_upload_form, !socket.assigns.show_upload_form)}
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :progress_photo, ref)}
  end

  def handle_event("save_photo", %{"notes" => notes}, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :progress_photo, fn %{path: path}, entry ->
        upload_dir = Path.join(["priv", "static", "uploads", "progress_photos"])
        File.mkdir_p!(upload_dir)

        filename = "#{entry.uuid}.#{ext(entry)}"
        dest = Path.join([upload_dir, filename])

        File.cp!(path, dest)

        {:ok, "/uploads/progress_photos/#{filename}"}
      end)

    case uploaded_files do
      [url | _] ->
        client = socket.assigns.client
        user = socket.assigns.current_user

        attrs = %{
          client_id: client.id,
          photo_url: url,
          date: DateTime.utc_now(),
          notes: if(notes == "", do: nil, else: notes)
        }

        result =
          Repo.transaction(fn ->
            case ProgressPhotos.create_progress_photo(attrs) do
              {:ok, photo} ->
                if client.trainer_id do
                  case Notifications.create_notification(%{
                         actor_id: user.id,
                         actor_type: "client",
                         recipient_id: client.trainer_id,
                         recipient_type: "trainer",
                         type: "progress_photo_uploaded",
                         data: %{photo_id: photo.id, client_id: client.id}
                       }) do
                    {:ok, notification} -> {photo, notification}
                    {:error, changeset} -> Repo.rollback(changeset)
                  end
                else
                  {photo, nil}
                end

              {:error, changeset} ->
                Repo.rollback(changeset)
            end
          end)

        case result do
          {:ok, {_photo, notification}} ->
            if notification do
              Phoenix.PubSub.broadcast(
                Crohnjobs.PubSub,
                "notifications:trainer:#{client.trainer_id}",
                {:notification, notification}
              )
            end

            photos = ProgressPhotos.list_progress_photos_for_client(client.id)

            {:noreply,
             socket
             |> assign(:photos, photos)
             |> assign(:show_upload_form, false)
             |> put_flash(:info, "Progress photo uploaded!")}

          {:error, changeset} ->
            IO.inspect(changeset.errors, label: "Progress Photo Errors")
            {:noreply, socket |> put_flash(:error, "Failed to save photo: #{inspect(changeset.errors)}")}
        end

      [] ->
        {:noreply, socket |> put_flash(:error, "No file was uploaded")}
    end
  end

  def handle_event("delete_photo", %{"id" => id}, socket) do
    client = socket.assigns.client
    photo = ProgressPhotos.get_progress_photo_for_client!(String.to_integer(id), client.id)

    if photo.photo_url do
      file_path = Path.join("priv/static", photo.photo_url)
      File.rm(file_path)
    end

    case ProgressPhotos.delete_progress_photo(photo) do
      {:ok, _} ->
        photos = ProgressPhotos.list_progress_photos_for_client(client.id)

        {:noreply,
         socket
         |> assign(:photos, photos)
         |> put_flash(:info, "Photo deleted")}

      {:error, _} ->
        {:noreply, socket |> put_flash(:error, "Failed to delete photo")}
    end
  end

  defp ext(entry) do
    [ext | _] = MIME.extensions(entry.client_type)
    ext
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-6xl mx-auto px-4 py-6">
      <div class="mb-6">
        <.link navigate={~p"/client"} class="text-emerald-600 hover:text-emerald-700 flex items-center gap-2">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"></path>
          </svg>
          Back to Dashboard
        </.link>
      </div>

      <div class="flex items-center justify-between mb-8">
        <div>
          <h1 class="text-3xl font-bold text-gray-900">Progress Photos</h1>
          <p class="text-sm text-gray-500 mt-1">Track your physical transformation over time</p>
        </div>
        <button
          phx-click="toggle_upload_form"
          class="inline-flex items-center px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white font-medium rounded-lg transition-colors"
        >
          <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>
          </svg>
          Upload Photo
        </button>
      </div>

      <%= if @show_upload_form do %>
        <div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden mb-6">
          <div class="px-6 py-4 border-b border-gray-100">
            <h2 class="text-xl font-semibold text-gray-900">Upload Progress Photo</h2>
          </div>
          <div class="p-6">
            <form phx-submit="save_photo" phx-change="validate" class="space-y-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Notes (optional)</label>
                <textarea name="notes" rows="2" class="w-full rounded-lg border-gray-300 shadow-sm focus:ring-emerald-500 focus:border-emerald-500" placeholder="e.g., Week 4 of program, feeling stronger"></textarea>
              </div>

              <div class="border-2 border-dashed border-gray-300 rounded-lg p-6 hover:border-emerald-400 transition-colors">
                <div class="text-center">
                  <svg class="mx-auto h-12 w-12 text-gray-400" stroke="currentColor" fill="none" viewBox="0 0 48 48">
                    <path d="M28 8H12a4 4 0 00-4 4v20m32-12v8m0 0v8a4 4 0 01-4 4H12a4 4 0 01-4-4v-4m32-4l-3.172-3.172a4 4 0 00-5.656 0L28 28M8 32l9.172-9.172a4 4 0 015.656 0L28 28m0 0l4 4m4-24h8m-4-4v8m-12 4h.02" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"></path>
                  </svg>
                  <div class="mt-4">
                    <label class="cursor-pointer">
                      <span class="mt-2 block text-sm font-medium text-gray-900">Click to upload or drag and drop</span>
                      <span class="mt-1 block text-xs text-gray-500">PNG, JPG, GIF up to 5MB</span>
                      <.live_file_input upload={@uploads.progress_photo} class="sr-only" />
                    </label>
                  </div>
                </div>

                <%= for entry <- @uploads.progress_photo.entries do %>
                  <div class="mt-4">
                    <div class="flex items-center justify-between text-sm">
                      <span class="text-gray-700"><%= entry.client_name %></span>
                      <button type="button" phx-click="cancel_upload" phx-value-ref={entry.ref} class="text-red-600 hover:text-red-800">Cancel</button>
                    </div>
                    <div class="mt-2 w-full bg-gray-200 rounded-full h-2">
                      <div class="bg-emerald-600 h-2 rounded-full transition-all" style={"width: #{entry.progress}%"}></div>
                    </div>
                  </div>
                  <%= for err <- upload_errors(@uploads.progress_photo, entry) do %>
                    <p class="mt-2 text-sm text-red-600"><%= error_to_string(err) %></p>
                  <% end %>
                <% end %>
              </div>

              <div class="flex gap-3">
                <%= if length(@uploads.progress_photo.entries) > 0 do %>
                  <button type="submit" class="flex-1 bg-emerald-600 hover:bg-emerald-700 text-white font-semibold py-3 rounded-lg transition-colors">
                    Upload Photo
                  </button>
                <% end %>
                <button type="button" phx-click="toggle_upload_form" class="px-4 py-2 text-gray-600 hover:text-gray-800 font-medium">Cancel</button>
              </div>
            </form>
          </div>
        </div>
      <% end %>

      <%= if length(@photos) == 0 do %>
        <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-12 text-center">
          <svg class="mx-auto h-16 w-16 text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
          </svg>
          <h3 class="mt-4 text-lg font-medium text-gray-900">No progress photos yet</h3>
          <p class="mt-2 text-sm text-gray-500">Upload your first progress photo to start tracking your transformation.</p>
        </div>
      <% else %>
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
          <%= for photo <- @photos do %>
            <div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden group">
              <div class="relative aspect-[3/4]">
                <img src={photo.photo_url} alt="Progress photo" class="w-full h-full object-cover" />
                <div class="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
                  <button
                    phx-click="delete_photo"
                    phx-value-id={photo.id}
                    data-confirm="Are you sure you want to delete this photo?"
                    class="bg-red-500 hover:bg-red-600 text-white rounded-full p-2"
                  >
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                    </svg>
                  </button>
                </div>
              </div>
              <div class="p-4">
                <p class="text-sm font-medium text-gray-900"><%= Calendar.strftime(photo.date, "%B %d, %Y") %></p>
                <%= if photo.notes do %>
                  <p class="text-sm text-gray-500 mt-1"><%= photo.notes %></p>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  defp error_to_string(:too_large), do: "File is too large (max 5MB)"
  defp error_to_string(:not_accepted), do: "File type not accepted (only JPG, PNG, GIF)"
  defp error_to_string(:too_many_files), do: "You can only upload one file"
  defp error_to_string(_), do: "Something went wrong"
end
