defmodule Scopestrength.Leads do
  import Ecto.Query
  alias Scopestrength.Repo
  alias Scopestrength.Leads.Lead

  @doc """
  Checks if an email has already been used for a demo.
  Returns {:ok, lead} if found, {:error, :not_found} if new email.
  """
  def check_lead(email) do
    normalized_email = String.downcase(email)

    case Repo.get_by(Lead, email: normalized_email) do
      nil -> {:error, :not_found}
      lead -> {:ok, lead}
    end
  end

  def create_lead(attrs) do
    %Lead{}
    |> Lead.changeset(attrs)
    |> Repo.insert()
  end

  def list_leads do
    Repo.all(from l in Lead, order_by: [desc: l.inserted_at])
  end
end
