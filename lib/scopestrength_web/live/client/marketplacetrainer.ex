defmodule ScopestrengthWeb.Client.Marketplacetrainer do
  alias Scopestrength.Trainers
  alias Scopestrength.Repo
  use ScopestrengthWeb, :live_view

  def handle_event("sendEmail", _params, socket) do
    {:noreply, socket |> put_flash(:info, "Email has been sent. Thank you!")}
  end

  def handle_event("requestTrainer", %{"id" => id}, socket) do
    client = socket.assigns.client
    trainer_id = String.to_integer(id)
    Scopestrength.ClientRequests.create_client_request(%{client_id: client.id, trainer_id: trainer_id})
    {:noreply, socket |> put_flash(:info, "Request sent!")}
  end

  def mount(params, _session, socket) do
    trainer_id = String.to_integer(params["trainer_id"])
    trainer = Repo.get_by(Trainers.Trainer, %{id: trainer_id}) |> Repo.preload([:user, :certifications])
    client = Repo.get_by(Scopestrength.Clients.Client, user_id: socket.assigns.current_user.id)
    {:ok, socket |> assign(trainer: trainer, client: client)}
  end

  def render(assigns) do
    ~H"""
    <div class="w-full max-w-4xl mx-auto space-y-5">

      <!-- Back link -->
      <.link navigate={~p"/client/marketplace"} class="inline-flex items-center gap-1.5 text-sm text-slate-500 hover:text-emerald-600 transition-colors">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
        </svg>
        Back to Trainers
      </.link>

      <!-- Header: avatar + name + certs + actions -->
      <div class="bg-white border border-slate-200 rounded-2xl p-6 flex flex-col sm:flex-row gap-5">
        <!-- Avatar -->
        <div class="w-32 h-32 bg-gradient-to-br from-emerald-400 to-emerald-600 rounded-xl flex items-center justify-center flex-shrink-0 self-start">
          <span class="text-white font-bold text-4xl">
            <%= String.first(@trainer.user.name || "?") |> String.upcase() %>
          </span>
        </div>

        <!-- Name + subtitle + certs -->
        <div class="flex-1 min-w-0">
          <h1 class="text-2xl font-bold text-slate-900"><%= @trainer.user.name %></h1>
          <p class="text-sm text-slate-500 mt-0.5">
            <%= [@trainer.style, @trainer.specialization] |> Enum.filter(& &1) |> Enum.join(" · ") %>
          </p>

          <!-- Certifications -->
          <%= if length(@trainer.certifications) > 0 do %>
            <div class="flex flex-wrap gap-2 mt-3">
              <%= for cert <- @trainer.certifications do %>
                <span class="inline-flex items-center gap-1 px-3 py-1 rounded-full border border-emerald-400 text-emerald-700 text-xs font-medium bg-white">
                  <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M5 13l4 4L19 7" />
                  </svg>
                  <%= cert.name %>
                </span>
              <% end %>
            </div>
          <% end %>
        </div>

        <!-- Action buttons -->
        <div class="flex flex-col gap-3 sm:items-end flex-shrink-0">
          <%= if @client && @client.trainer_id != @trainer.id do %>
            <button
              phx-click="requestTrainer"
              phx-value-id={@trainer.id}
              class="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-slate-900 hover:bg-slate-700 text-white text-sm font-semibold transition shadow-sm"
            >
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
              Request Trainer
            </button>
          <% else %>
            <span class="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-emerald-100 text-emerald-700 text-sm font-semibold">
              Your Trainer
            </span>
          <% end %>
          <span class="font-bold">
          <%=@trainer.user.email%>
          </span>

        </div>
      </div>

      <!-- Bio + Specialties row -->
      <div class="grid grid-cols-1 sm:grid-cols-2 gap-5">
        <!-- Bio -->
        <div class="bg-white border border-slate-200 rounded-2xl p-5">
          <h2 class="text-sm font-semibold text-slate-700 mb-3">Bio</h2>
          <%= if @trainer.bio do %>
            <p class="text-sm text-slate-600 leading-relaxed"><%= @trainer.bio %></p>
          <% else %>
            <p class="text-sm text-slate-400 italic">No bio provided.</p>
          <% end %>
        </div>

        <!-- Specialties & Skills -->
        <div class="bg-white border border-slate-200 rounded-2xl p-5">
          <h2 class="text-sm font-semibold text-slate-700 mb-3">Specialties &amp; Skills</h2>
          <div class="flex flex-wrap gap-2">
            <%= if @trainer.specialization do %>
              <%= for skill <- String.split(@trainer.specialization, ~r/[,·\/]/) |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == "")) do %>
                <span class="px-3 py-1 rounded-full border border-slate-300 text-slate-600 text-xs font-medium">
                  <%= skill %>
                </span>
              <% end %>
            <% end %>
            <%= if @trainer.style do %>
              <span class="px-3 py-1 rounded-full border border-slate-300 text-slate-600 text-xs font-medium capitalize">
                <%= @trainer.style %>
              </span>
            <% end %>
            <%= if !@trainer.specialization && !@trainer.style do %>
              <p class="text-sm text-slate-400 italic">Not specified.</p>
            <% end %>
          </div>
        </div>
      </div>

      <!-- Pricing + Availability row -->
      <div class="grid grid-cols-1 sm:grid-cols-2 gap-5">
        <!-- Pricing -->
        <div class="bg-white border border-slate-200 rounded-2xl p-5">
          <h2 class="text-sm font-semibold text-slate-700 mb-3">Pricing</h2>
          <%= if @trainer.price_per_month do %>
            <div class="space-y-3">
              <div class="flex justify-between items-center py-2 border-b border-slate-100 text-sm">
                <span class="text-slate-600">Monthly plan</span>
                <span class="font-semibold text-slate-900">$<%= @trainer.price_per_month %><span class="text-xs font-normal text-slate-500">/mo</span></span>
              </div>
              <%= if @trainer.price_per_session do %>
              <div class="space-y-3">
              <div class="flex justify-between items-center py-2 border-b border-slate-100 text-sm">
                <span class="text-slate-600">
                Session Plan
                </span>
                <span class="font-semi-bold text-slate-900">
               $<%=@trainer.price_per_session %>
                </span>
                </div>
                </div>

              <%end%>

            </div>
          <% else %>
            <p class="text-sm text-slate-400 italic">Price on request.</p>
          <% end %>

        </div>

        <!-- Availability -->
        <div class="bg-white border border-slate-200 rounded-2xl p-5">
          <h2 class="text-sm font-semibold text-slate-700 mb-3">Availability</h2>
          <% days = [{"M", true}, {"T", true}, {"W", true}, {"T", true}, {"F", true}, {"S", false}, {"S", false}] %>
          <div class="flex gap-2 mb-3">
            <%= for {day, active} <- days do %>
              <div class={[
                "w-9 h-9 rounded-full flex items-center justify-center text-xs font-semibold",
                (if active, do: "bg-emerald-100 text-emerald-700 border border-emerald-300", else: "bg-slate-100 text-slate-400 border border-slate-200")
              ]}>
                <%= day %>
              </div>
            <% end %>
          </div>
          <p class="text-xs text-slate-500">
            <%= [@trainer.format, if(@trainer.location, do: @trainer.location)] |> Enum.filter(& &1) |> Enum.join(" · ") %>
            <%= if @trainer.years_experience do %>
              · <%= @trainer.years_experience %> yrs exp.
            <% end %>
          </p>
        </div>
      </div>

    </div>
    """
  end

end
