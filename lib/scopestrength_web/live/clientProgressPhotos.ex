defmodule ScopestrengthWeb.ClientProgressPhotos do
  use ScopestrengthWeb, :live_view

  alias Scopestrength.Trainers
  alias Scopestrength.Clients.Client
  alias Scopestrength.ProgressPhotos
  alias Scopestrength.Repo

  def mount(params, _session, socket) do
    user = socket.assigns.current_user
    trainer = Trainers.get_trainer_byUserId(user.id)
    client_id = String.to_integer(params["id"])

    case Repo.get(Client, client_id) |> Repo.preload(:user) do
      nil ->
        {:ok, socket |> put_flash(:error, "Client not found") |> redirect(to: "/trainer/clients")}

      client ->
        if client.trainer_id == trainer.id do
          photos = ProgressPhotos.list_progress_photos_for_client(client.id)

          {:ok,
           socket
           |> assign(:client, client)
           |> assign(:photos, photos)}
        else
          {:ok, socket |> put_flash(:error, "Client not found") |> redirect(to: "/trainer/clients")}
        end
    end
  end

  def render(assigns) do
    ~H"""
    <div class="w-full min-h-screen">
      <div class="w-full px-0 sm:px-2 lg:px-4 pt-10 pb-4">
        <div class="flex items-center justify-between">
          <div>
            <h1 class="text-3xl lg:text-4xl font-semibold tracking-tight text-slate-900">
              <span class="text-emerald-700"><%= @client.user.name %></span>'s Progress Photos
            </h1>
            <p class="mt-2 text-slate-600 text-base lg:text-lg">Visual progress tracking</p>
          </div>
          <.link
            navigate={~p"/trainer/clients/#{@client.id}"}
            class="inline-flex items-center px-4 py-2 bg-slate-600 hover:bg-slate-700 text-white font-medium rounded-lg transition-colors"
          >
            <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
            </svg>
            Back to Client
          </.link>
        </div>
      </div>

      <div class="w-full px-0 sm:px-2 lg:px-4 py-6">
        <%= if length(@photos) == 0 do %>
          <div class="bg-white rounded-2xl shadow-sm border border-slate-200 p-12 text-center">
            <svg class="mx-auto h-16 w-16 text-slate-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
            </svg>
            <h3 class="mt-4 text-lg font-medium text-slate-900">No progress photos yet</h3>
            <p class="mt-2 text-sm text-slate-500">This client hasn't uploaded any progress photos.</p>
          </div>
        <% else %>
          <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            <%= for photo <- @photos do %>
              <div class="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
                <div class="relative aspect-[3/4]">
                  <img src={photo.photo_url} alt="Progress photo" class="w-full h-full object-cover" />
                </div>
                <div class="p-4">
                  <p class="text-sm font-medium text-slate-900"><%= Calendar.strftime(photo.date, "%B %d, %Y") %></p>
                  <%= if photo.notes do %>
                    <p class="text-sm text-slate-500 mt-1 line-clamp-2"><%= photo.notes %></p>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
