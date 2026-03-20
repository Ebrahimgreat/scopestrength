defmodule CrohnjobsWeb.Demosignupflow.CreateUser do
  use Reactor.Step

  @impl true
  def run(_arguments, _context, _options) do
    Crohnjobs.Account.generate_demo_account()
  end
end
