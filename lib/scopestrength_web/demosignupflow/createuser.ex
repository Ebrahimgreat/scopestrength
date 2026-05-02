defmodule ScopestrengthWeb.Demosignupflow.CreateUser do
  use Reactor.Step

  @impl true
  def run(_arguments, _context, _options) do
    Scopestrength.Account.generate_demo_account()
  end
end
