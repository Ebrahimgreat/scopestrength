# ScopeStrength - personal trainer management application
# Copyright (C) 2026  Ebrahim Shahid Arshad
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# SPDX-License-Identifier: AGPL-3.0-or-later

defmodule Scopestrength.ApiTokens do
  @moduledoc """
  Issuing, verifying and revoking API tokens.

  Tokens read `sst_<prefix>_<secret>`. The prefix is stored in clear and is how
  a row is found; the secret is only ever compared as a SHA-256 hash, in
  constant time. That split means verification needs no query against secret
  data, and a leaked database still yields nothing a caller could present.
  """
  import Ecto.Query, warn: false

  alias Scopestrength.Repo
  alias Scopestrength.ApiTokens.ApiToken

  @rand_size 32
  @prefix_size 6
  @hash_algorithm :sha256

  @doc """
  Creates a token for a client and returns the plaintext exactly once.

  Returns `{:ok, token_string, %ApiToken{}}`. The plaintext cannot be recovered
  afterwards -- if it is lost, the token has to be revoked and reissued.
  """
  def create_token(%{client_id: client_id, user_id: user_id} = attrs) do
    prefix = random_string(@prefix_size)
    secret = random_string(@rand_size)
    plaintext = "sst_#{prefix}_#{secret}"

    %ApiToken{}
    |> ApiToken.changeset(%{
      name: Map.get(attrs, :name),
      scope: Map.get(attrs, :scope, "read"),
      expires_at: expires_at(Map.get(attrs, :expires_in_days)),
      prefix: prefix,
      token_hash: hash(secret),
      client_id: client_id,
      user_id: user_id
    })
    |> Repo.insert()
    |> case do
      {:ok, token} -> {:ok, plaintext, token}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc """
  Verifies a presented token.

  Returns `{:ok, %ApiToken{}}` with `:client` and `:user` preloaded, or
  `{:error, reason}`. Every failure reason is deliberately vague to the caller:
  the plug turns them all into the same 401 so a probe cannot learn whether a
  token exists, has expired, or was revoked.
  """
  def verify_token(presented) when is_binary(presented) do
    with {:ok, prefix, secret} <- split(presented),
         %ApiToken{} = token <- fetch_by_prefix(prefix),
         true <- Plug.Crypto.secure_compare(hash(secret), token.token_hash),
         true <- ApiToken.active?(token) do
      {:ok, touch(token)}
    else
      nil -> {:error, :invalid_token}
      false -> {:error, :invalid_token}
      {:error, reason} -> {:error, reason}
    end
  end

  def verify_token(_), do: {:error, :invalid_token}

  @doc """
  Tokens belonging to a client, newest first. Revoked ones are included so the
  UI can show what was withdrawn and when.
  """
  def list_for_client(client_id) do
    ApiToken
    |> where([t], t.client_id == ^client_id)
    |> order_by([t], desc: t.inserted_at)
    |> Repo.all()
  end

  @doc """
  Revokes a token, scoped to its owner.

  The client id is required rather than implied: a token id alone must never be
  enough to revoke somebody else's credential.
  """
  def revoke_token(client_id, token_id) do
    ApiToken
    |> where([t], t.id == ^token_id and t.client_id == ^client_id)
    |> Repo.one()
    |> case do
      nil ->
        {:error, :not_found}

      token ->
        token
        |> ApiToken.changeset(%{revoked_at: DateTime.utc_now() |> DateTime.truncate(:second)})
        |> Repo.update()
    end
  end

  @doc """
  Whether a token's scope permits writing.
  """
  def can_write?(%ApiToken{scope: "read_write"}), do: true
  def can_write?(_), do: false

  # --- internals -------------------------------------------------------------

  defp fetch_by_prefix(prefix) do
    ApiToken
    |> where([t], t.prefix == ^prefix)
    |> preload([:client, :user])
    |> Repo.one()
  end

  # last_used_at is what tells you a leaked token is being used. It is written
  # on every verified call, so a missing value means genuinely never used.
  defp touch(token) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    {:ok, updated} =
      token
      |> Ecto.Changeset.change(last_used_at: now)
      |> Repo.update()

    %{updated | client: token.client, user: token.user}
  end

  defp split("sst_" <> rest) do
    case String.split(rest, "_", parts: 2) do
      [prefix, secret] when byte_size(prefix) > 0 and byte_size(secret) > 0 ->
        {:ok, prefix, secret}

      _ ->
        {:error, :malformed_token}
    end
  end

  defp split(_), do: {:error, :malformed_token}

  defp hash(secret), do: :crypto.hash(@hash_algorithm, secret)

  defp random_string(size) do
    size
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end

  defp expires_at(nil), do: nil

  defp expires_at(days) when is_integer(days) and days > 0 do
    DateTime.utc_now()
    |> DateTime.add(days * 24 * 3600, :second)
    |> DateTime.truncate(:second)
  end

  defp expires_at(days) when is_binary(days) do
    case Integer.parse(days) do
      {n, ""} -> expires_at(n)
      _ -> nil
    end
  end

  defp expires_at(_), do: nil
end
