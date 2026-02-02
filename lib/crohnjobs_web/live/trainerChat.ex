defmodule CrohnjobsWeb.TrainerChat do
alias Crohnjobs.Clients.Client
alias Crohnjobs.Repo
alias Crohnjobs.Trainers
  use CrohnjobsWeb, :live_view
  import Ecto.Query


  def mount(_params, session, socket) do
    user = socket.assigns.current_user
    trainer = Trainers.get_trainer_byUserId(user.id)
    clients = Repo.all(from c in Client, where: c.trainer_id == ^trainer.id)|>Repo.preload(:user)
    {:ok, assign(socket, clients: clients)}



  end
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto p-4">
      <h1 class="text-xl font-semibold text-slate-900 mb-4">Messages</h1>

      <%= if length(@clients) == 0 do %>
        <div class="text-center py-12 text-slate-500">
          <p class="text-base font-medium text-slate-700">No clients yet</p>
          <p class="mt-1 text-sm">Once you have clients, you can chat with them here.</p>
        </div>
      <% else %>
        <div class="bg-white border border-slate-200 rounded-lg divide-y divide-slate-200">
          <%= for client <- @clients do %>
            <.link navigate={~p"/chat/#{client.id}"} class="block hover:bg-slate-50 transition-colors">
              <div class="flex items-center px-4 py-3">
                <div class="flex-shrink-0">
                  <div class="h-10 w-10 rounded-full bg-slate-100 flex items-center justify-center text-slate-700 font-semibold text-sm">
                    <%= String.first(client.user.name || "?") |> String.upcase() %>
                  </div>
                </div>
                <div class="ml-4 flex-1">
                  <p class="text-sm font-medium text-slate-900"><%= client.user.name %></p>
                  <p class="text-xs text-slate-500">Tap to chat</p>
                </div>
              </div>
            </.link>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

end
