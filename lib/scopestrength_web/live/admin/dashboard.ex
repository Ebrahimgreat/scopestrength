defmodule ScopestrengthWeb.Admin.Dashboard do
  use ScopestrengthWeb, :live_view
  alias Scopestrength.Repo
  import Ecto.Query

  def mount(_params, _session, socket) do
    leads = Repo.all(from l in Scopestrength.Leads.Lead, order_by: [desc: l.inserted_at])

    total_leads = length(leads)

    today = Date.utc_today()
    leads_today = Enum.count(leads, fn l ->
      Date.compare(DateTime.to_date(l.inserted_at), today) == :eq
    end)

    total_trainers = Repo.one(
      from u in Scopestrength.Account.User,
      where: u.role == "trainer" and u.type != "demo",
      select: count(u.id)
    )

    total_clients = Repo.one(
      from u in Scopestrength.Account.User,
      where: u.role == "client" and u.type != "demo",
      select: count(u.id)
    )

    {:ok, assign(socket,
      leads: leads,
      total_leads: total_leads,
      leads_today: leads_today,
      total_trainers: total_trainers,
      total_clients: total_clients
    )}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h1 class="text-2xl font-bold text-slate-800">Dashboard</h1>

      <!-- Stat Cards -->
      <div class="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <div class="bg-white rounded-xl border border-slate-200 p-5 shadow-sm">
          <p class="text-xs font-medium text-slate-500 uppercase tracking-wide">Total Leads</p>
          <p class="mt-2 text-3xl font-bold text-slate-800">{@total_leads}</p>
          <p class="mt-1 text-xs text-slate-400">demo signups</p>
        </div>
        <div class="bg-white rounded-xl border border-slate-200 p-5 shadow-sm">
          <p class="text-xs font-medium text-slate-500 uppercase tracking-wide">New Today</p>
          <p class="mt-2 text-3xl font-bold text-violet-600">{@leads_today}</p>
          <p class="mt-1 text-xs text-slate-400">leads today</p>
        </div>
        <div class="bg-white rounded-xl border border-slate-200 p-5 shadow-sm">
          <p class="text-xs font-medium text-slate-500 uppercase tracking-wide">Trainers</p>
          <p class="mt-2 text-3xl font-bold text-slate-800">{@total_trainers}</p>
          <p class="mt-1 text-xs text-slate-400">real accounts</p>
        </div>
        <div class="bg-white rounded-xl border border-slate-200 p-5 shadow-sm">
          <p class="text-xs font-medium text-slate-500 uppercase tracking-wide">Clients</p>
          <p class="mt-2 text-3xl font-bold text-slate-800">{@total_clients}</p>
          <p class="mt-1 text-xs text-slate-400">real accounts</p>
        </div>
      </div>

      <!-- Leads Table -->
      <div class="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
        <div class="px-6 py-4 border-b border-slate-100 flex items-center justify-between">
          <h2 class="text-base font-semibold text-slate-800">Demo Leads</h2>
          <span class="text-xs text-slate-400">{@total_leads} total</span>
        </div>

        <div :if={@leads == []} class="px-6 py-12 text-center text-slate-400 text-sm">
          No leads yet
        </div>

        <table :if={@leads != []} class="min-w-full divide-y divide-slate-100">
          <thead class="bg-slate-50">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Email</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Signed Up</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Time</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-100">
            <%= for lead <- @leads do %>
              <tr class="hover:bg-slate-50 transition-colors">
                <td class="px-6 py-4 text-sm font-medium text-slate-800">
                  {lead.email}
                </td>
                <td class="px-6 py-4 text-sm text-slate-500">
                  {Calendar.strftime(lead.inserted_at, "%d %b %Y")}
                </td>
                <td class="px-6 py-4 text-sm text-slate-400">
                  {Calendar.strftime(lead.inserted_at, "%H:%M")}
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
    """
  end
end
