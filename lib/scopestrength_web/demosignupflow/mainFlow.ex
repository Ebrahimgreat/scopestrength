defmodule ScopestrengthWeb.Demosignupflow.MainFlow do
  use Reactor

  alias ScopestrengthWeb.Demosignupflow.{Checklead, CreateUser, CreateLead}

  input :email

  step :check_lead, Checklead do
    argument :email, input(:email)
  end

  step :create_user, CreateUser do
    wait_for :check_lead
  end

  step :create_lead, CreateLead do
    argument :email, input(:email)
    argument :user, result(:create_user)
  end

  return :create_user
end
