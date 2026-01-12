defmodule CrohnjobsWeb.ClientDashboard do
alias Crohnjobs.Programmes.ProgrammeUser
alias Crohnjobs.Programmes
alias Crohnjobs.Programmes.Programme
alias Crohnjobs.Accounts.Trainer
alias Crohnjobs.Clients.Client
alias Crohnjobs.DownloadProgramme
alias Crohnjobs.Invites
alias Crohnjobs.Repo
  use CrohnjobsWeb, :live_view

  def handle_event("submit_invite_code", %{"code" => code}, socket) do
    user = socket.assigns.current_user
    client = socket.assigns.client

    case Invites.redeem_invite(code, user.email) do
      {:ok, trainer_id} ->
        case Invites.link_client_to_trainer(client.id, trainer_id) do
          {:ok, updated_client} ->
            client = Repo.get!(Client, client.id) |> Repo.preload(trainer: :user)
            {:noreply, socket
              |> assign(client: client, invite_code: "")
              |> put_flash(:info, "Successfully linked with your trainer!")}

          {:error, _} ->
            {:noreply, socket |> put_flash(:error, "Failed to link with trainer")}
        end

      {:error, :invalid_code} ->
        {:noreply, socket |> put_flash(:error, "Invalid invite code")}

      {:error, :already_used} ->
        {:noreply, socket |> put_flash(:error, "This invite code has already been used")}

      {:error, :email_mismatch} ->
        {:noreply, socket |> put_flash(:error, "This invite code was created for a different email address")}

      {:error, _} ->
        {:noreply, socket |> put_flash(:error, "Something went wrong")}
    end
  end

  def handle_event("update_invite_code", %{"code" => code}, socket) do
    {:noreply, assign(socket, invite_code: code)}
  end

  def handle_event("downloadProgramme", _, socket) do
    programme =
    Repo.get!(Programme, socket.assigns.current_programme.programme_id)
    |> Repo.preload(programmeTemplates: [programmeDetails: :exercise])
    IO.inspect(programme.id)
    DownloadProgramme.downloadProgramme(%{programme: programme})
     {:noreply, assign(socket, report: true)}
    end

  def mount(_params, session, socket) do
    user = socket.assigns.current_user
    client = Repo.get_by(Client, %{user_id: user.id})|>Repo.preload(trainer: :user)
    currentProgramme = Repo.get_by(ProgrammeUser,%{client_id: client.id})
    |> case do
      nil -> nil
      pu -> Repo.preload(pu, [programme: [programmeTemplates: [programmeDetails: :exercise]]])
    end

    {:ok,assign(socket, report: false, client: client, current_programme: currentProgramme, invite_code: "")}
  end
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h1 class="text-2xl font-bold">
        <%= if @client.trainer == nil do %>
          You currently have no trainer
        <% else %>
          Your Trainer: <%= @client.trainer.user.name %>
        <% end %>
      </h1>

      <%= if @client.trainer == nil do %>
        <!-- Invite Code Entry -->
        <div class="bg-white rounded-2xl shadow-lg p-6 border border-gray-100">
          <div class="flex items-center space-x-3 mb-4">
            <div class="p-2 bg-emerald-100 rounded-lg">
              <svg class="w-6 h-6 text-emerald-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z"></path>
              </svg>
            </div>
            <h2 class="text-xl font-bold text-gray-900">Have an invite code?</h2>
          </div>
          <p class="text-gray-600 mb-4">Enter the invite code from your trainer to connect with them.</p>
          <form phx-submit="submit_invite_code" class="space-y-4">
            <div>
              <input
                type="text"
                name="code"
                value={@invite_code}
                phx-change="update_invite_code"
                placeholder="Enter invite code (e.g., ABC12345)"
                class="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500 transition-all duration-200 font-mono text-lg tracking-wider uppercase"
              />
            </div>
            <.button
              type="submit"
              class="bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-700 hover:to-teal-700 text-white px-6 py-3 rounded-xl shadow-lg hover:shadow-xl transition-all duration-200 font-semibold"
            >
              Connect with Trainer
            </.button>
          </form>
        </div>
      <% end %>

      <%= if @current_programme do %>

      <%= if @report == false do %>
               <.button
                 phx-click="downloadProgramme"
                 class="bg-emerald-500 hover:bg-emerald-600 text-white font-semibold px-6 py-3 rounded-xl shadow-lg hover:shadow-xl transform hover:scale-105 transition-all duration-300 flex items-center justify-center space-x-2"
               >
                 <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                   <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                 </svg>
                 <span>Generate Report</span>
               </.button>
             <% end %>

         <%= if @report == true do %>
           <div class="mt-8 p-6 bg-white bg-opacity-20 backdrop-blur-sm rounded-2xl border border-white border-opacity-30">
             <div class="flex items-center space-x-4">
               <div class="w-12 h-12 bg-emerald-500 rounded-full flex items-center justify-center">
                 <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                   <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
                 </svg>
               </div>
               <div class="flex-1">
                 <h3 class="text-lg font-semibold text-white">Report Generated Successfully!</h3>
                 <p class="text-indigo-100">Your programme report is ready for download</p>
               </div>
               <a
                 class="bg-emerald-500 hover:bg-emerald-600 text-white px-6 py-3 rounded-xl shadow-lg hover:shadow-xl transition-all duration-200 flex items-center space-x-2 font-semibold transform hover:scale-105"
                 href="/download/workout"
               >
                 <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                   <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0l-3-3m3 3l3-3m-3-4H7a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-3"/>
                 </svg>
                 <span>Download Now</span>
               </a>
             </div>
           </div>
         <% end %>



        <div class="bg-white shadow rounded-lg p-6">
          <h2 class="text-xl font-semibold mb-4">
          <b>Current Programme</b> :
          <%= @current_programme.programme.name %></h2>
          <p class="text-gray-600 mb-4"><%= @current_programme.programme.description %></p>

          <div class="space-y-4">
            <%= for template <- @current_programme.programme.programmeTemplates do %>
              <div class="border rounded-lg p-4">
                <h3 class="text-lg font-medium mb-2"><%= template.name %></h3>
                <table class="min-w-full">
                  <thead>
                    <tr class="text-left text-sm text-gray-500">
                      <th class="pb-2">Exercise</th>
                      <th class="pb-2">Sets</th>
                      <th class="pb-2">Reps</th>

                    </tr>
                  </thead>
                  <tbody>
                    <%= for detail <- template.programmeDetails do %>
                      <tr class="border-t">
                        <td class="py-2"><%= detail.exercise.name %></td>
                        <td class="py-2"><%= detail.set %></td>
                        <td class="py-2"><%= detail.reps %></td>
                        <td class="py-2"><%= detail.rir %></td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>
            <% end %>
          </div>
        </div>
      <% else %>
        <div class="bg-gray-100 rounded-lg p-6 text-center">
          <p class="text-gray-600">You don't have an assigned programme yet.</p>
        </div>
      <% end %>
    </div>
    """
  end


end
