defmodule ScopestrengthWeb.Client.Weight do
  use ScopestrengthWeb, :live_view
  alias Scopestrength.Repo
  alias Scopestrength.Clients
  alias Scopestrength.ClientWeight
  alias Scopestrength.ClientWeight.ClientWeights
  alias Scopestrength.Notifications

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    client = Clients.get_client_byUserId(user.id)
    weights = ClientWeight.list_client_weights_for_client(client.id)
    form = ClientWeights.changeset(%ClientWeights{}, %{}) |> to_form(as: "client_weights")

    {:ok,
     socket
     |> assign(:client, client)
     |> assign(:weights, weights)
     |> assign(:form, form)
     |> assign(:show_modal, false)}
  end

  def handle_event("open_modal", _params, socket) do
    {:noreply, assign(socket, show_modal: !socket.assigns.show_modal)}
  end

  def handle_event("add_weight", %{"client_weights" => params}, socket) do
    user = socket.assigns.current_user
    client = socket.assigns.client

    date =
      case Date.from_iso8601(params["date"]) do
        {:ok, d} -> d
        _ -> nil
      end

    result =
      Repo.transaction(fn ->
        case ClientWeight.upsert_weight(client.id, date, params["weight"]) do
          {:ok, weight_entry} ->
            if client.trainer_id do
              case Notifications.create_notification(%{
                     actor_id: user.id,
                     actor_type: "client",
                     recipient_id: client.trainer_id,
                     recipient_type: "trainer",
                     type: "weight_logged",
                     data: %{weight_id: weight_entry.id, client_id: client.id, weight: params["weight"]}
                   }) do
                {:ok, notification} -> {weight_entry, notification}
                {:error, changeset} -> Repo.rollback(changeset)
              end
            else
              {weight_entry, nil}
            end

          {:error, changeset} ->
            Repo.rollback(changeset)
        end
      end)

    case result do
      {:ok, {_weight_entry, notification}} ->
        if notification do
          Phoenix.PubSub.broadcast(
            Scopestrength.PubSub,
            "notifications:trainer:#{client.trainer_id}",
            {:notification, notification}
          )
        end

        weights = ClientWeight.list_client_weights_for_client(client.id)

        {:noreply,
         socket
         |> assign(show_modal: false, weights: weights)
         |> put_flash(:info, "Weight logged successfully!")}

      {:error, _changeset} ->
        {:noreply, socket |> put_flash(:error, "Failed to save weight")}
    end
  end

  def handle_event("delete_weight", %{"id" => id}, socket) do
    id = String.to_integer(id)
    weight = ClientWeight.get_client_weights!(id)

    case ClientWeight.delete_client_weights(weight) do
      {:ok, _} ->
        weights = Enum.reject(socket.assigns.weights, &(&1.id == id))
        {:noreply, assign(socket, weights: weights)}

      _ ->
        {:noreply, socket |> put_flash(:error, "Failed to delete weight")}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-emerald-50 via-teal-50 to-cyan-50 py-8 px-4 sm:px-6 lg:px-8">
      <div class="max-w-4xl mx-auto">

        <div class="mb-6">
          <.link navigate={~p"/client"} class="text-emerald-600 hover:text-emerald-700 flex items-center gap-2">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"></path>
            </svg>
            Back to Dashboard
          </.link>
        </div>

        <div class="bg-white rounded-2xl shadow-xl p-8 mb-6 border border-emerald-100">
          <div class="flex items-center justify-between">
            <div>
              <h1 class="text-4xl font-bold bg-gradient-to-r from-emerald-600 to-teal-600 bg-clip-text text-transparent mb-2">
                Weight Tracker
              </h1>
              <p class="text-gray-600">Track your weight over time and monitor your progress</p>
            </div>
            <button
              phx-click="open_modal"
              class="bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-700 hover:to-teal-700 text-white font-semibold px-6 py-3 rounded-xl shadow-lg hover:shadow-xl transition-all duration-200 flex items-center gap-2">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z" clip-rule="evenodd" />
              </svg>
              Log Weight
            </button>
          </div>
        </div>

        <%= if @show_modal do %>
          <div class="fixed inset-0 bg-black bg-opacity-60 flex items-center justify-center z-50 p-4 backdrop-blur-sm">
            <div class="bg-white rounded-2xl shadow-2xl w-full max-w-md transform transition-all">
              <div class="p-6 border-b border-gray-200 bg-gradient-to-r from-emerald-50 to-teal-50">
                <h2 class="text-2xl font-bold text-gray-900">Log Weight</h2>
                <p class="text-gray-600 text-sm mt-1">Record your weight for today</p>
              </div>

              <.form phx-submit="add_weight" for={@form}>
                <div class="p-6 space-y-5">
                  <div>
                    <label class="block text-sm font-semibold text-gray-700 mb-2">Date</label>
                    <.input
                      type="date"
                      required
                      field={@form[:date]}
                    />
                  </div>

                  <div>
                    <label class="block text-sm font-semibold text-gray-700 mb-2">Weight (kg)</label>
                    <.input
                      type="number"
                      field={@form[:weight]}
                      step="0.1"
                      min="0"
                      required
                      placeholder="e.g. 75.5"
                    />
                  </div>
                </div>

                <div class="p-6 bg-gray-50 rounded-b-2xl flex gap-3">
                  <button
                    type="button"
                    phx-click="open_modal"
                    class="flex-1 bg-white border-2 border-gray-300 text-gray-700 font-semibold px-6 py-3 rounded-xl hover:bg-gray-50 transition-all duration-200">
                    Cancel
                  </button>
                  <.button class="flex-1 bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-700 hover:to-teal-700 text-white font-semibold px-6 py-3 rounded-xl shadow-md hover:shadow-lg transition-all duration-200">
                    Save Weight
                  </.button>
                </div>
              </.form>
            </div>
          </div>
        <% end %>

        <!-- Trend Chart -->
        <%= if length(@weights) >= 2 do %>
          <div class="bg-white rounded-2xl shadow-lg p-6 mb-6 border border-emerald-100">
            <h2 class="text-xl font-bold text-gray-900 mb-4">Weight Trend</h2>
            <% values = Enum.map(@weights, &Decimal.to_float(&1.weight)) %>
            <% # Compute EMA (Exponential Moving Average) with alpha = 2/(N+1), N=min(5, count) %>
            <% ema_values = case values do
              [first | rest] ->
                alpha = 2.0 / (min(5, length(values)) + 1)
                {ema_list, _} = Enum.reduce(rest, {[first], first}, fn val, {acc, prev_ema} ->
                  new_ema = alpha * val + (1 - alpha) * prev_ema
                  {acc ++ [new_ema], new_ema}
                end)
                ema_list
              _ -> values
            end %>
            <div class="relative" style="height: 250px;">
              <svg viewBox="0 0 800 250" class="w-full h-full" preserveAspectRatio="xMidYMid meet">
                <% min_val = min(Enum.min(values), Enum.min(ema_values)) - 1 %>
                <% max_val = max(Enum.max(values), Enum.max(ema_values)) + 1 %>
                <% range = max(max_val - min_val, 1) %>
                <% count = length(values) %>
                <% padding_x = 60 %>
                <% padding_y = 20 %>
                <% chart_w = 800 - padding_x * 2 %>
                <% chart_h = 250 - padding_y * 2 %>

                <!-- Grid lines -->
                <%= for i <- 0..4 do %>
                  <% y = padding_y + chart_h - (i / 4 * chart_h) %>
                  <% label = Float.round(min_val + (i / 4 * range), 1) %>
                  <line x1={padding_x} y1={y} x2={800 - padding_x} y2={y} stroke="#e5e7eb" stroke-width="1" />
                  <text x={padding_x - 10} y={y + 4} text-anchor="end" class="fill-gray-500" font-size="12"><%= label %></text>
                <% end %>

                <!-- Actual weight line -->
                <polyline
                  fill="none"
                  stroke="url(#gradient)"
                  stroke-width="3"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  points={Enum.map_join(Enum.with_index(values), " ", fn {val, i} ->
                    x = padding_x + (i / max(count - 1, 1) * chart_w)
                    y = padding_y + chart_h - ((val - min_val) / range * chart_h)
                    "#{x},#{y}"
                  end)}
                />

                <!-- Area fill -->
                <polygon
                  fill="url(#area-gradient)"
                  opacity="0.3"
                  points={
                    Enum.map_join(Enum.with_index(values), " ", fn {val, i} ->
                      x = padding_x + (i / max(count - 1, 1) * chart_w)
                      y = padding_y + chart_h - ((val - min_val) / range * chart_h)
                      "#{x},#{y}"
                    end) <>
                    " #{padding_x + chart_w},#{padding_y + chart_h} #{padding_x},#{padding_y + chart_h}"
                  }
                />

                <!-- EMA trend line (dashed) -->
                <polyline
                  fill="none"
                  stroke="#f59e0b"
                  stroke-width="2.5"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-dasharray="8,4"
                  points={Enum.map_join(Enum.with_index(ema_values), " ", fn {val, i} ->
                    x = padding_x + (i / max(count - 1, 1) * chart_w)
                    y = padding_y + chart_h - ((val - min_val) / range * chart_h)
                    "#{x},#{y}"
                  end)}
                />

                <!-- Data points -->
                <%= for {val, i} <- Enum.with_index(values) do %>
                  <% x = padding_x + (i / max(count - 1, 1) * chart_w) %>
                  <% y = padding_y + chart_h - ((val - min_val) / range * chart_h) %>
                  <circle cx={x} cy={y} r="5" fill="white" stroke="#059669" stroke-width="2.5" />
                <% end %>

                <defs>
                  <linearGradient id="gradient" x1="0%" y1="0%" x2="100%" y2="0%">
                    <stop offset="0%" stop-color="#059669" />
                    <stop offset="100%" stop-color="#0d9488" />
                  </linearGradient>
                  <linearGradient id="area-gradient" x1="0%" y1="0%" x2="0%" y2="100%">
                    <stop offset="0%" stop-color="#059669" />
                    <stop offset="100%" stop-color="#059669" stop-opacity="0" />
                  </linearGradient>
                </defs>
              </svg>
            </div>
            <!-- Legend -->
            <div class="flex items-center justify-center gap-6 mt-3 text-sm text-gray-600">
              <div class="flex items-center gap-2">
                <div class="w-6 h-0.5 bg-emerald-600 rounded"></div>
                <span>Actual Weight</span>
              </div>
              <div class="flex items-center gap-2">
                <div class="w-6 h-0.5 bg-amber-500 rounded" style="border-top: 2px dashed #f59e0b; background: none;"></div>
                <span>Trend (EMA)</span>
              </div>
            </div>
            <div class="flex justify-between text-xs text-gray-500 mt-2 px-14">
              <span><%= List.first(@weights).date %></span>
              <span><%= List.last(@weights).date %></span>
            </div>
          </div>
        <% end %>

        <!-- Summary Stats -->
        <%= if length(@weights) > 0 do %>
          <% values = Enum.map(@weights, &Decimal.to_float(&1.weight)) %>
          <% latest = List.last(values) %>
          <% first_val = List.first(values) %>
          <% diff = Float.round(latest - first_val, 1) %>
          <% # Compute EMA for stats card %>
          <% trend_weight = case values do
            [first | rest] ->
              alpha = 2.0 / (min(5, length(values)) + 1)
              Enum.reduce(rest, first, fn val, prev_ema ->
                alpha * val + (1 - alpha) * prev_ema
              end)
            _ -> latest
          end %>
          <% trend_diff = Float.round(trend_weight - first_val, 1) %>
          <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
            <div class="bg-white rounded-xl shadow-md p-5 border border-emerald-100">
              <p class="text-sm text-gray-500 mb-1">Current Weight</p>
              <p class="text-2xl font-bold text-gray-900"><%= Float.round(latest, 1) %> kg</p>
            </div>
            <div class="bg-white rounded-xl shadow-md p-5 border border-emerald-100">
              <p class="text-sm text-gray-500 mb-1">Starting Weight</p>
              <p class="text-2xl font-bold text-gray-900"><%= Float.round(first_val, 1) %> kg</p>
            </div>
            <div class="bg-white rounded-xl shadow-md p-5 border border-emerald-100">
              <p class="text-sm text-gray-500 mb-1">Total Change</p>
              <p class={"text-2xl font-bold #{if diff <= 0, do: "text-emerald-600", else: "text-red-500"}"}>
                <%= if diff > 0, do: "+", else: "" %><%= diff %> kg
              </p>
            </div>
            <div class="bg-white rounded-xl shadow-md p-5 border border-amber-100">
              <p class="text-sm text-gray-500 mb-1">Trend Weight</p>
              <p class="text-2xl font-bold text-amber-600"><%= Float.round(trend_weight, 1) %> kg</p>
              <p class={"text-xs mt-1 #{if trend_diff <= 0, do: "text-emerald-600", else: "text-red-500"}"}>
                <%= if trend_diff > 0, do: "+", else: "" %><%= trend_diff %> kg from start
              </p>
            </div>
          </div>
        <% end %>

        <!-- Weight Log List -->
        <%= if length(@weights) > 0 do %>
          <div class="bg-white rounded-2xl shadow-lg border border-emerald-100 overflow-hidden">
            <div class="px-6 py-4 border-b border-gray-100">
              <h2 class="text-xl font-bold text-gray-900">Weight Log</h2>
            </div>
            <div class="divide-y divide-gray-100">
              <%= for weight <- Enum.reverse(@weights) do %>
                <div class="px-6 py-4 flex items-center justify-between hover:bg-emerald-50 transition-colors">
                  <div class="flex items-center gap-4">
                    <div class="w-10 h-10 bg-gradient-to-br from-emerald-100 to-teal-100 rounded-lg flex items-center justify-center flex-shrink-0">
                      <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-emerald-600" viewBox="0 0 20 20" fill="currentColor">
                        <path fill-rule="evenodd" d="M6 2a1 1 0 00-1 1v1H4a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V6a2 2 0 00-2-2h-1V3a1 1 0 10-2 0v1H7V3a1 1 0 00-1-1zm0 5a1 1 0 000 2h8a1 1 0 100-2H6z" clip-rule="evenodd" />
                      </svg>
                    </div>
                    <div>
                      <span class="text-sm text-gray-500"><%= weight.date %></span>
                      <p class="text-lg font-semibold text-gray-900"><%= weight.weight %> kg</p>
                    </div>
                  </div>
                  <button
                    phx-click="delete_weight"
                    phx-value-id={weight.id}
                    data-confirm="Are you sure you want to delete this entry?"
                    class="text-red-400 hover:text-red-600 transition-colors">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                      <path fill-rule="evenodd" d="M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm5-1a1 1 0 00-1 1v6a1 1 0 102 0V8a1 1 0 00-1-1z" clip-rule="evenodd" />
                    </svg>
                  </button>
                </div>
              <% end %>
            </div>
          </div>
        <% else %>
          <div class="bg-white rounded-2xl shadow-lg p-12 text-center border border-emerald-100">
            <div class="w-24 h-24 bg-gradient-to-br from-emerald-100 to-teal-100 rounded-full flex items-center justify-center mx-auto mb-6">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-12 w-12 text-emerald-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 6l3 1m0 0l-3 9a5.002 5.002 0 006.001 0M6 7l3 9M6 7l6-2m6 2l3-1m-3 1l-3 9a5.002 5.002 0 006.001 0M18 7l3 9m-3-9l-6-2m0-2v2m0 16V5m0 16H9m3 0h3" />
              </svg>
            </div>
            <h3 class="text-2xl font-bold text-gray-900 mb-2">No Weight Entries Yet</h3>
            <p class="text-gray-600 mb-6">Start tracking your weight to see your progress over time.</p>
            <button
              phx-click="open_modal"
              class="inline-flex items-center gap-2 bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-700 hover:to-teal-700 text-white font-semibold px-6 py-3 rounded-xl shadow-lg hover:shadow-xl transition-all duration-200">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z" clip-rule="evenodd" />
              </svg>
              Log Your First Weight
            </button>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
