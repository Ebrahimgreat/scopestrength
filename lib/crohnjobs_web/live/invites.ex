defmodule CrohnjobsWeb.Invites do
  use CrohnjobsWeb, :live_view
  alias Crohnjobs.Trainers
  alias Crohnjobs.Invites

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    trainer = Trainers.get_trainer_byUserId(user.id)
    invites = Invites.list_invites_for_trainer(trainer.id)

    {:ok, assign(socket,
      trainer_id: trainer.id,
      invites: invites,
      email: "",
      show_form: false,
      new_invite: nil
    )}
  end

  def handle_event("toggle_form", _params, socket) do
    {:noreply, assign(socket, show_form: !socket.assigns.show_form, email: "", new_invite: nil)}
  end

  def handle_event("update_email", %{"email" => email}, socket) do
    {:noreply, assign(socket, email: email)}
  end

  def handle_event("create_invite", %{"email" => email}, socket) do
    case Invites.create_invite(socket.assigns.trainer_id, email) do
      {:ok, invite} ->
        invites = Invites.list_invites_for_trainer(socket.assigns.trainer_id)
        {:noreply, socket
          |> assign(invites: invites, new_invite: invite, email: "")
          |> put_flash(:info, "Invite created successfully!")}

      {:error, changeset} ->
        error_msg = changeset.errors |> Enum.map(fn {k, {msg, _}} -> "#{k} #{msg}" end) |> Enum.join(", ")
        {:noreply, socket |> put_flash(:error, "Error: #{error_msg}")}
    end
  end

  def handle_event("delete_invite", %{"id" => id}, socket) do
    case Invites.delete_invite(String.to_integer(id), socket.assigns.trainer_id) do
      {:ok, _} ->
        invites = Invites.list_invites_for_trainer(socket.assigns.trainer_id)
        {:noreply, socket
          |> assign(invites: invites)
          |> put_flash(:info, "Invite deleted")}

      {:error, _} ->
        {:noreply, socket |> put_flash(:error, "Could not delete invite")}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-zinc-50">
      <!-- Header Section -->
      <div class="bg-white shadow-lg border-b border-gray-100">
        <div class="w-full px-6 lg:px-10 py-8">
          <div class="flex items-center justify-between">
            <div class="flex items-center space-x-4">
              <div class="p-3 bg-gradient-to-r from-emerald-500 to-teal-600 rounded-xl shadow-lg">
                <svg class="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"></path>
                </svg>
              </div>
              <div>
                <h1 class="text-3xl font-bold text-gray-900">Client Invites</h1>
                <p class="text-gray-600 mt-1">Invite clients to connect with you</p>
              </div>
            </div>

            <.button
              phx-click="toggle_form"
              class="bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-700 hover:to-teal-700 text-white px-6 py-3 rounded-xl shadow-lg hover:shadow-xl transform hover:-translate-y-0.5 transition-all duration-200 flex items-center space-x-2 font-semibold"
            >
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
              </svg>
              <span>New Invite</span>
            </.button>
          </div>
        </div>
      </div>

      <div class="w-full px-6 lg:px-10 py-8">
        <!-- Create Invite Form -->
        <%= if @show_form do %>
          <div class="bg-white rounded-2xl shadow-lg p-6 mb-8 border border-gray-100">
            <h2 class="text-xl font-bold text-gray-900 mb-4">Create New Invite</h2>
            <form phx-submit="create_invite" class="space-y-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">Client Email</label>
                <input
                  type="email"
                  name="email"
                  value={@email}
                  phx-change="update_email"
                  placeholder="client@example.com"
                  required
                  class="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500 transition-all duration-200"
                />
                <p class="mt-2 text-sm text-gray-500">Only this email address can use the generated invite code.</p>
              </div>
              <div class="flex space-x-3">
                <.button
                  type="submit"
                  class="bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-700 hover:to-teal-700 text-white px-6 py-3 rounded-xl shadow-lg hover:shadow-xl transition-all duration-200 font-semibold"
                >
                  Generate Invite Code
                </.button>
                <.button
                  type="button"
                  phx-click="toggle_form"
                  class="bg-gray-200 hover:bg-gray-300 text-gray-700 px-6 py-3 rounded-xl transition-all duration-200 font-semibold"
                >
                  Cancel
                </.button>
              </div>
            </form>
          </div>
        <% end %>

        <!-- New Invite Success -->
        <%= if @new_invite do %>
          <div class="bg-emerald-50 border border-emerald-200 rounded-2xl p-6 mb-8">
            <div class="flex items-start space-x-4">
              <div class="p-2 bg-emerald-500 rounded-full">
                <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
                </svg>
              </div>
              <div class="flex-1">
                <h3 class="text-lg font-bold text-emerald-800">Invite Created!</h3>
                <p class="text-emerald-700 mt-1">Share this code with your client (<%= @new_invite.email %>):</p>
                <div class="mt-3 bg-white border-2 border-emerald-300 rounded-xl p-4 flex items-center justify-between">
                  <span class="text-2xl font-mono font-bold text-gray-900 tracking-wider"><%= @new_invite.code %></span>
                </div>
                <p class="text-sm text-emerald-600 mt-2">The client will enter this code after registering to link with you.</p>
              </div>
            </div>
          </div>
        <% end %>

        <!-- Stats -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
          <div class="bg-white rounded-2xl shadow-lg p-6 border border-gray-100">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-medium text-gray-600 uppercase tracking-wider">Pending Invites</p>
                <p class="text-3xl font-bold text-gray-900 mt-2"><%= Enum.count(@invites, & !&1.used) %></p>
              </div>
              <div class="p-3 bg-amber-100 rounded-full">
                <svg class="w-8 h-8 text-amber-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                </svg>
              </div>
            </div>
          </div>
          <div class="bg-white rounded-2xl shadow-lg p-6 border border-gray-100">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-medium text-gray-600 uppercase tracking-wider">Accepted Invites</p>
                <p class="text-3xl font-bold text-gray-900 mt-2"><%= Enum.count(@invites, & &1.used) %></p>
              </div>
              <div class="p-3 bg-emerald-100 rounded-full">
                <svg class="w-8 h-8 text-emerald-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                </svg>
              </div>
            </div>
          </div>
        </div>

        <!-- Invites List -->
        <%= if @invites == [] do %>
          <div class="text-center py-16">
            <div class="mx-auto w-24 h-24 bg-gray-100 rounded-full flex items-center justify-center mb-6">
              <svg class="w-12 h-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"></path>
              </svg>
            </div>
            <h3 class="text-xl font-semibold text-gray-900 mb-2">No invites yet</h3>
            <p class="text-gray-600 mb-8 max-w-md mx-auto">Create invite codes to allow clients to connect with you.</p>
          </div>
        <% else %>
          <div class="bg-white rounded-2xl shadow-lg border border-gray-100 overflow-hidden">
            <table class="min-w-full divide-y divide-gray-200">
              <thead class="bg-gray-50">
                <tr>
                  <th class="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">Email</th>
                  <th class="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">Code</th>
                  <th class="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">Status</th>
                  <th class="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">Created</th>
                  <th class="px-6 py-4 text-right text-xs font-semibold text-gray-600 uppercase tracking-wider">Actions</th>
                </tr>
              </thead>
              <tbody class="bg-white divide-y divide-gray-200">
                <%= for invite <- @invites do %>
                  <tr class="hover:bg-gray-50 transition-colors duration-150">
                    <td class="px-6 py-4 whitespace-nowrap">
                      <span class="text-sm text-gray-900"><%= invite.email %></span>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap">
                      <span class="font-mono text-sm font-semibold text-gray-900 bg-gray-100 px-3 py-1 rounded-lg"><%= invite.code %></span>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap">
                      <%= if invite.used do %>
                        <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-emerald-100 text-emerald-800">
                          <svg class="w-3 h-3 mr-1" fill="currentColor" viewBox="0 0 20 20">
                            <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path>
                          </svg>
                          Used
                        </span>
                      <% else %>
                        <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-amber-100 text-amber-800">
                          <svg class="w-3 h-3 mr-1" fill="currentColor" viewBox="0 0 20 20">
                            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-12a1 1 0 10-2 0v4a1 1 0 00.293.707l2.828 2.829a1 1 0 101.415-1.415L11 9.586V6z" clip-rule="evenodd"></path>
                          </svg>
                          Pending
                        </span>
                      <% end %>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      <%= Calendar.strftime(invite.inserted_at, "%b %d, %Y") %>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-right">
                      <%= if !invite.used do %>
                        <.button
                          phx-click="delete_invite"
                          phx-value-id={invite.id}
                          data-confirm="Are you sure you want to delete this invite?"
                          class="bg-red-500 hover:bg-red-600 text-white px-3 py-2 rounded-lg text-sm transition-all duration-200"
                        >
                          Delete
                        </.button>
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
