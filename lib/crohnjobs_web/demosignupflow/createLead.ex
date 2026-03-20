defmodule CrohnjobsWeb.Demosignupflow.CreateLead do
  use Reactor.Step

  @impl true
  def run(%{email: email, user: user}, _context, _options) do
    Crohnjobs.Leads.create_lead(%{email: email, demo_user_id: user.id})
  end
end
