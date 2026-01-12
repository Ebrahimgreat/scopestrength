defmodule Crohnjobs.Invites do
  import Ecto.Query, warn: false
  alias Crohnjobs.Repo
  alias Crohnjobs.Invites.Invite
  alias Crohnjobs.Clients.Client

  @doc """
  Creates an invite for a specific email from a trainer.
  Generates a unique 8-character code.
  """
  def create_invite(trainer_id, email) do
    code = generate_unique_code()

    %Invite{}
    |> Invite.changeset(%{code: code, email: String.downcase(email), trainer_id: trainer_id})
    |> Repo.insert()
  end

  @doc """
  Validates and redeems an invite code for a client.
  Returns {:ok, trainer_id} if valid, {:error, reason} otherwise.
  """
  def redeem_invite(code, client_email) do
    email = String.downcase(client_email)

    case Repo.get_by(Invite, code: code) do
      nil ->
        {:error, :invalid_code}

      %Invite{used: true} ->
        {:error, :already_used}

      %Invite{email: invite_email} when invite_email != email ->
        {:error, :email_mismatch}

      %Invite{} = invite ->
        invite
        |> Invite.changeset(%{used: true})
        |> Repo.update()
        |> case do
          {:ok, updated_invite} -> {:ok, updated_invite.trainer_id}
          {:error, _} -> {:error, :update_failed}
        end
    end
  end

  @doc """
  Links a client to a trainer after successful invite redemption.
  """
  def link_client_to_trainer(client_id, trainer_id) do
    client = Repo.get!(Client, client_id)

    client
    |> Client.changeset(%{trainer_id: trainer_id})
    |> Repo.update()
  end

  @doc """
  Gets all invites for a trainer.
  """
  def list_invites_for_trainer(trainer_id) do
    Invite
    |> where([i], i.trainer_id == ^trainer_id)
    |> order_by([i], desc: i.inserted_at)
    |> Repo.all()
  end

  @doc """
  Deletes an invite (only if unused).
  """
  def delete_invite(invite_id, trainer_id) do
    case Repo.get_by(Invite, id: invite_id, trainer_id: trainer_id, used: false) do
      nil -> {:error, :not_found}
      invite -> Repo.delete(invite)
    end
  end

  # Generates a unique 8-character alphanumeric code
  defp generate_unique_code do
    code =
      :crypto.strong_rand_bytes(6)
      |> Base.url_encode64()
      |> binary_part(0, 8)
      |> String.upcase()

    # Ensure uniqueness
    case Repo.get_by(Invite, code: code) do
      nil -> code
      _ -> generate_unique_code()
    end
  end
end
