defmodule CrohnjobsWeb.Demosignupflow.Checklead do
  use Reactor.Step

  @impl true
  def run(%{email: email}, _context, _options) do
    case Crohnjobs.Leads.check_lead(email) do
      {:ok, _lead} -> {:error, :already_tried}
      {:error, :not_found} -> {:ok, :new}
    end
  end
end
