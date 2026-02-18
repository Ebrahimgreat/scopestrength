defmodule CrohnjobsWeb.Admin.Dashboard do
  use CrohnjobsWeb, :live_view
  alias Crohnjobs.Repo
  import Ecto.Query


  def mount(params, session, socket) do
    leads = Repo.all(from  Crohnjobs.Leads.Lead)
{:ok,assign(socket,leads: leads)}

  end
  def render(assigns) do
    ~H"""
    Hi Admin
    <table class="min-w-full divide-y divide-gray-200">
    <thead class="bg-gray-50">

    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
    Email
    </th>

    </thead>
    <tbody class="bg-white divide-y divide-gray-200">
    <%=for lead <-@leads do%>

    <tr class="hover:bg-gray-50 transition-colors duration-150">
    <td class="px-6 py-4 whitespace-nowrap">
    <%=lead.email%>


    </td>
    </tr>
    <%end%>
    </tbody>
    </table>

    """

  end

end
