defmodule ScopestrengthWeb.Client.Marketplace do
  use ScopestrengthWeb, :live_view

  alias Scopestrength.Repo
  import Ecto.Query

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    client = Repo.get_by(Scopestrength.Clients.Client, user_id: user.id)

    trainers =
      Repo.all(from t in Scopestrength.Trainers.Trainer, where: t.is_demo == false and t.is_public == true )
      |> Repo.preload([:user, :certifications])

    current_assigned = client && Enum.find(trainers, fn t -> t.id == client.trainer_id end)
    IO.inspect(current_assigned)

    {:ok, assign(socket, client: client, trainers: trainers, current_assigned: current_assigned, search: "", filter_format: "all")}
  end
  def handle_event("requestTrainer", %{"id"=>id}, socket) do
    client = socket.assigns.client
    trainer_id = String.to_integer(id)
    Scopestrength.ClientRequests.create_client_request(%{client_id: client.id, trainer_id: trainer_id})
    {:noreply,socket}


  end

  def handle_event("search", %{"search" => query}, socket) do
    {:noreply, assign(socket, search: String.downcase(query))}
  end

  def handle_event("filter_format", %{"format" => format}, socket) do
    {:noreply, assign(socket, filter_format: format)}
  end

  defp filtered_trainers(trainers, search, format) do
    Enum.filter(trainers, fn t ->
      name = String.downcase(t.user.name || "")
      spec = String.downcase(t.specialization || "")
      location = String.downcase(t.location || "")

      matches_search =
        search == "" or
          String.contains?(name, search) or
          String.contains?(spec, search) or
          String.contains?(location, search)

      matches_format = format == "all" or t.format == format

      matches_search and matches_format
    end)
  end

  def render(assigns) do
    ~H"""
    <div class="w-full">
      <!-- Header -->
      <div class="mb-6">
        <h1 class="text-2xl font-semibold text-slate-900">Find a Trainer</h1>
        <p class="text-sm text-slate-500 mt-1">Browse coaches and request to work with one</p>
      </div>

      <!-- Current trainer banner -->
      <%= if @current_assigned do %>
        <div class="flex items-center gap-3 mb-6 p-4 bg-emerald-50 border border-emerald-200 rounded-xl">
          <div class="w-9 h-9 bg-gradient-to-br from-emerald-400 to-emerald-600 rounded-full flex items-center justify-center flex-shrink-0">
            <span class="text-white font-semibold text-sm">
              <%= String.first(@current_assigned.user.name || "?") |> String.upcase() %>
            </span>
          </div>
          <div>
            <p class="text-xs text-emerald-600 font-medium">Your current trainer</p>
            <p class="text-sm font-semibold text-emerald-900"><%= @current_assigned.user.name %></p>
          </div>
        </div>
      <% end %>

      <!-- Filters -->
      <div class="flex flex-col sm:flex-row gap-3 mb-6">
        <div class="relative flex-1">
          <svg class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
          <input
            type="text"
            placeholder="Search by name, specialization, location..."
            class="w-full pl-9 pr-4 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-transparent"
            phx-keyup="search"
            name="search"
            value={@search}
          />
        </div>

        <div class="flex gap-2 flex-wrap">
          <%= for {label, val} <- [{"All", "all"}, {"Online", "online"}, {"In-Person", "in-person"}, {"Hybrid", "hybrid"}] do %>
            <button
              phx-click="filter_format"
              phx-value-format={val}
              class={[
                "px-3 py-2 rounded-lg text-xs font-medium transition whitespace-nowrap",
                if @filter_format == val do
                  "bg-emerald-600 text-white shadow-sm"
                else
                  "bg-slate-100 text-slate-600 hover:bg-slate-200"
                end
              ]}
            >
              <%= label %>
            </button>
          <% end %>
        </div>
      </div>

      <!-- Trainer Grid -->
      <% visible = filtered_trainers(@trainers, @search, @filter_format) %>
      <%= if visible == [] do %>
        <div class="text-center py-16 bg-slate-50/50 rounded-lg border border-slate-200">
          <div class="inline-flex items-center justify-center w-12 h-12 rounded-full bg-slate-100 mb-3">
            <svg class="w-6 h-6 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
          </div>
          <h3 class="text-base font-medium text-slate-900 mb-1">No trainers found</h3>
          <p class="text-sm text-slate-500">Try adjusting your search or filters</p>
        </div>
      <% else %>
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          <%= for trainer <- visible do %>
            <div
              phx-click={JS.navigate(~p"/client/marketplace/#{trainer.id}")}
              class="bg-white border border-slate-200 rounded-xl p-5 hover:shadow-md hover:border-emerald-200 transition-all cursor-pointer group"
            >
              <!-- Avatar + availability -->
              <div class="flex items-start gap-3 mb-4">
                <div class="w-12 h-12 bg-gradient-to-br from-emerald-400 to-emerald-600 rounded-full flex items-center justify-center flex-shrink-0">
                  <span class="text-white font-semibold text-base">
                    <%= String.first(trainer.user.name || "?") |> String.upcase() %>
                  </span>
                </div>
                <div class="flex-1 min-w-0">
                  <h3 class="text-sm font-semibold text-slate-900 truncate group-hover:text-emerald-700 transition-colors">
                    <%= trainer.user.name %>
                  </h3>
                  <%= if trainer.specialization do %>
                    <p class="text-xs text-slate-500 truncate"><%= trainer.specialization %></p>
                  <% end %>
                </div>
                <span class={[
                  "inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium flex-shrink-0",
                  if trainer.availability do
                    "bg-emerald-100 text-emerald-700"
                  else
                    "bg-slate-100 text-slate-500"
                  end
                ]}>
                  <div class={[
                    "w-1.5 h-1.5 rounded-full",
                    (if trainer.availability, do: "bg-emerald-500", else: "bg-slate-400")
                  ]}></div>
                  <%= if trainer.availability, do: "Available", else: "Full" %>
                </span>
              </div>

              <!-- Bio -->
              <%= if trainer.bio do %>
                <p class="text-xs text-slate-600 line-clamp-2 mb-4"><%= trainer.bio %></p>
              <% end %>

              <!-- Tags -->
              <div class="flex flex-wrap gap-1.5 mb-4">
                <%= if trainer.format do %>
                  <span class="px-2 py-0.5 bg-slate-100 text-slate-600 text-xs rounded-md"><%= trainer.format %></span>
                <% end %>
                <%= if trainer.style do %>
                  <span class="px-2 py-0.5 bg-slate-100 text-slate-600 text-xs rounded-md"><%= trainer.style %></span>
                <% end %>
                <%= if trainer.location do %>
                  <span class="px-2 py-0.5 bg-slate-100 text-slate-600 text-xs rounded-md flex items-center gap-1">
                    <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                    </svg>
                    <%= trainer.location %>
                  </span>
                <% end %>
                <%= if trainer.years_experience do %>
                  <span class="px-2 py-0.5 bg-slate-100 text-slate-600 text-xs rounded-md">
                    <%= trainer.years_experience %>yr exp
                  </span>
                <% end %>
              </div>

              <!-- Footer -->
              <div class="flex items-center justify-between pt-3 border-t border-slate-100">
              <%= if is_nil(@current_assigned) or @current_assigned.id != trainer.id do %>
              <span phx-click="requestTrainer" phx-value-id={trainer.id} phx-click-self class="inline-flex cursor-pointer items-center px-3 py-1.5 rounded-lg bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-medium transition" onclick="event.stopPropagation()">
                Request
              </span>
              <% else %>
              <span class="text-xs text-emerald-700 font-medium">Trainer Already Assigned</span>
              <% end %>
                <span class="text-sm font-semibold text-slate-900">
                  <%= if trainer.price_per_month do %>
                    $<%= trainer.price_per_month %><span class="text-xs font-normal text-slate-500">/mo</span>
                  <% else %>
                    <span class="text-xs text-slate-400">Price on request</span>
                  <% end %>
                </span>
                <%= if length(trainer.certifications) > 0 do %>
                  <span class="text-xs text-slate-500 flex items-center gap-1">
                    <svg class="w-3.5 h-3.5 text-emerald-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z" />
                    </svg>
                    <%= length(trainer.certifications) %> cert<%= if length(trainer.certifications) > 1, do: "s" %>
                  </span>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end
end
