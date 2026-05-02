defmodule ScopestrengthWeb.ClientChat do
  alias Scopestrength.Clients.Client
  alias Scopestrength.Repo
  use ScopestrengthWeb, :live_view

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    client = Repo.get_by(Client, %{user_id: user.id}) |> Repo.preload(:trainer)
    trainer = client && client.trainer

    {:ok, assign(socket, client: client, trainer: trainer)}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto p-4">
      <h1 class="text-xl font-semibold text-slate-900 mb-4">Messages</h1>

      <%= if @trainer do %>
        <div class="bg-white border border-slate-200 rounded-lg">
          <.link navigate={~p"/chat/#{@client.id}"} class="block hover:bg-slate-50 transition-colors">
            <div class="flex items-center px-4 py-3">
              <div class="flex-shrink-0">
                <div class="h-10 w-10 rounded-full bg-slate-100 flex items-center justify-center text-slate-700 font-semibold text-sm">
                  T
                </div>
              </div>
              <div class="ml-4 flex-1">
                <p class="text-sm font-medium text-slate-900">Your Trainer</p>
                <p class="text-xs text-slate-500">Tap to chat</p>
              </div>
            </div>
          </.link>
        </div>
      <% else %>
        <div class="text-center py-12 text-slate-500">
          <p class="text-base font-medium text-slate-700">No trainer assigned</p>
          <p class="mt-1 text-sm">You'll be able to chat once a trainer is assigned to you.</p>
        </div>
      <% end %>
    </div>
    """
  end
end
