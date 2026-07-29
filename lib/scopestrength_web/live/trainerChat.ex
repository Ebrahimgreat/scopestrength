defmodule ScopestrengthWeb.TrainerChat do
alias Scopestrength.Clients.Client
alias Scopestrength.Repo
alias Scopestrength.Trainers
  use ScopestrengthWeb, :live_view
  import Ecto.Query


  def mount(_params, session, socket) do
    user = socket.assigns.current_user
    trainer = Trainers.get_trainer_byUserId(user.id)
    clients = Repo.all(from c in Client, where: c.trainer_id == ^trainer.id)|>Repo.preload(:user)
    {:ok, assign(socket, clients: clients)}



  end
  def render(assigns) do
    ~H"""
    <div class="max-w-lg mx-auto px-4 pt-8">
      <h1 class="text-xl font-semibold text-foreground mb-3">Messages</h1>

      <%= if length(@clients) == 0 do %>
        <div class="text-center py-16">
          <p class="text-sm text-dim">No clients yet. Once you have clients, you can chat with them here.</p>
        </div>
      <% else %>
        <div class="divide-y divide-line">
          <%= for client <- @clients do %>
            <.link navigate={~p"/chat/#{client.id}"} class="flex items-center gap-3 py-3 hover:opacity-70 transition-opacity">
              <div class="h-9 w-9 rounded-full bg-secondary flex items-center justify-center text-dim font-medium text-sm flex-shrink-0">
                <%= String.first(client.user.name || "?") |> String.upcase() %>
              </div>
              <span class="text-sm font-medium text-foreground"><%= client.user.name %></span>
            </.link>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

end
