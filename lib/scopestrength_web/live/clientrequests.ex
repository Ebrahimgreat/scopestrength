defmodule ScopestrengthWeb.Clientrequests do
  alias Scopestrength.Trainers
  alias Scopestrength.ClientRequests
  use ScopestrengthWeb, :live_view

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    trainer = Trainers.get_trainer_byUserId(user.id)
    requests = ClientRequests.list_requests_for_trainer(trainer.id)

    {:ok, assign(socket, trainer_id: trainer.id, requests: requests)}
  end

  def handle_event("accept", %{"id" => id}, socket) do
    case ClientRequests.accept_request(String.to_integer(id), socket.assigns.trainer_id) do
      {:ok, _} ->
        requests = ClientRequests.list_requests_for_trainer(socket.assigns.trainer_id)
        {:noreply, socket |> assign(requests: requests) |> put_flash(:info, "Request accepted — client linked to your account.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not accept request.")}
    end
  end

  def handle_event("reject", %{"id" => id}, socket) do
    case ClientRequests.reject_request(String.to_integer(id), socket.assigns.trainer_id) do
      {:ok, _} ->
        requests = ClientRequests.list_requests_for_trainer(socket.assigns.trainer_id)
        {:noreply, socket |> assign(requests: requests) |> put_flash(:info, "Request rejected.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not reject request.")}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="w-full min-h-screen">
      <div class="w-full px-0 sm:px-2 lg:px-4 pt-10 pb-4">
        <h1 class="text-3xl font-bold text-gray-900">Client Requests</h1>
        <p class="text-gray-600 mt-1">Clients who found you on the marketplace and want to train with you.</p>
      </div>

      <div class="w-full px-0 sm:px-2 lg:px-4 py-4">
        <!-- Stats -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <div class="bg-white rounded-2xl shadow-lg p-6 border border-gray-100">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-medium text-gray-600 uppercase tracking-wider">Pending</p>
                <p class="text-3xl font-bold text-gray-900 mt-2"><%= Enum.count(@requests, &(&1.status == "pending")) %></p>
              </div>
              <div class="p-3 bg-amber-100 rounded-full">
                <svg class="w-8 h-8 text-amber-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
            </div>
          </div>
          <div class="bg-white rounded-2xl shadow-lg p-6 border border-gray-100">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-medium text-gray-600 uppercase tracking-wider">Accepted</p>
                <p class="text-3xl font-bold text-gray-900 mt-2"><%= Enum.count(@requests, &(&1.status == "accepted")) %></p>
              </div>
              <div class="p-3 bg-emerald-100 rounded-full">
                <svg class="w-8 h-8 text-emerald-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
            </div>
          </div>
          <div class="bg-white rounded-2xl shadow-lg p-6 border border-gray-100">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-medium text-gray-600 uppercase tracking-wider">Rejected</p>
                <p class="text-3xl font-bold text-gray-900 mt-2"><%= Enum.count(@requests, &(&1.status == "rejected")) %></p>
              </div>
              <div class="p-3 bg-red-100 rounded-full">
                <svg class="w-8 h-8 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
            </div>
          </div>
        </div>

        <!-- Requests List -->
        <%= if @requests == [] do %>
          <div class="text-center py-16">
            <div class="mx-auto w-24 h-24 bg-gray-100 rounded-full flex items-center justify-center mb-6">
              <svg class="w-12 h-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z" />
              </svg>
            </div>
            <h3 class="text-xl font-semibold text-gray-900 mb-2">No requests yet</h3>
            <p class="text-gray-600 max-w-md mx-auto">When clients find you on the marketplace and request to train with you, they'll appear here.</p>
          </div>
        <% else %>
          <div class="bg-white rounded-2xl shadow-lg border border-gray-100 overflow-hidden">
            <table class="min-w-full divide-y divide-gray-200">
              <thead class="bg-gray-50">
                <tr>
                  <th class="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">Client</th>
                  <th class="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">Message</th>
                  <th class="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">Status</th>
                  <th class="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">Received</th>
                  <th class="px-6 py-4 text-right text-xs font-semibold text-gray-600 uppercase tracking-wider">Actions</th>
                </tr>
              </thead>
              <tbody class="bg-white divide-y divide-gray-200">
                <%= for request <- @requests do %>
                  <tr class="hover:bg-gray-50 transition-colors duration-150">
                    <td class="px-6 py-4 whitespace-nowrap">
                      <div class="flex items-center gap-3">
                        <div class="h-9 w-9 rounded-full bg-gradient-to-br from-emerald-400/30 to-emerald-600/30 border border-emerald-400/30 flex items-center justify-center text-sm font-semibold text-emerald-700">
                          <%= String.first(request.client.user.name || "?") %>
                        </div>
                        <div>
                          <p class="text-sm font-medium text-gray-900"><%= request.client.user.name %></p>
                          <p class="text-xs text-gray-500"><%= request.client.user.email %></p>
                        </div>
                      </div>
                    </td>
                    <td class="px-6 py-4 max-w-xs">
                      <p class="text-sm text-gray-600 truncate"><%= request.message || "—" %></p>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap">
                      <%= case request.status do %>
                        <% "pending" -> %>
                          <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-amber-100 text-amber-800">
                            <svg class="w-3 h-3 mr-1" fill="currentColor" viewBox="0 0 20 20">
                              <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-12a1 1 0 10-2 0v4a1 1 0 00.293.707l2.828 2.829a1 1 0 101.415-1.415L11 9.586V6z" clip-rule="evenodd" />
                            </svg>
                            Pending
                          </span>
                        <% "accepted" -> %>
                          <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-emerald-100 text-emerald-800">
                            <svg class="w-3 h-3 mr-1" fill="currentColor" viewBox="0 0 20 20">
                              <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
                            </svg>
                            Accepted
                          </span>
                        <% "rejected" -> %>
                          <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-red-100 text-red-800">
                            <svg class="w-3 h-3 mr-1" fill="currentColor" viewBox="0 0 20 20">
                              <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
                            </svg>
                            Rejected
                          </span>
                        <% _ -> %>
                          <span class="text-sm text-gray-500"><%= request.status %></span>
                      <% end %>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      <%= Calendar.strftime(request.inserted_at, "%b %d, %Y") %>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-right">
                      <%= if request.status == "pending" do %>
                        <div class="flex items-center justify-end gap-2">
                          <.button
                            phx-click="accept"
                            phx-value-id={request.id}
                            data-confirm="Accept this client request?"
                            class="bg-emerald-600 hover:bg-emerald-700 text-white px-3 py-2 rounded-lg text-sm transition-all duration-200"
                          >
                            Accept
                          </.button>
                          <.button
                            phx-click="reject"
                            phx-value-id={request.id}
                            data-confirm="Reject this request?"
                            class="bg-red-500 hover:bg-red-600 text-white px-3 py-2 rounded-lg text-sm transition-all duration-200"
                          >
                            Reject
                          </.button>
                        </div>
                      <% end %>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
