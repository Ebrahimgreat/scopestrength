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

defmodule Scopestrength.ApiTokens.ApiToken do
  @moduledoc """
  A credential one caller uses to read (and optionally write) one client's data.

  The token itself is never stored -- only its SHA-256 hash, plus a short
  non-secret prefix used to find the row. The plaintext is returned once, at
  creation, and cannot be recovered afterwards.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @scopes ~w(read read_write)

  schema "api_tokens" do
    field :name, :string
    field :token_hash, :binary
    field :prefix, :string
    field :scope, :string, default: "read"
    field :expires_at, :utc_datetime
    field :last_used_at, :utc_datetime
    field :revoked_at, :utc_datetime

    belongs_to :client, Scopestrength.Clients.Client
    belongs_to :user, Scopestrength.Account.User

    timestamps(type: :utc_datetime)
  end

  def changeset(token, attrs) do
    token
    |> cast(attrs, [
      :name,
      :token_hash,
      :prefix,
      :scope,
      :expires_at,
      :last_used_at,
      :revoked_at,
      :client_id,
      :user_id
    ])
    |> validate_required([:name, :token_hash, :prefix, :scope, :client_id, :user_id])
    |> validate_length(:name, min: 1, max: 60)
    |> validate_inclusion(:scope, @scopes)
    |> unique_constraint(:prefix)
    |> foreign_key_constraint(:client_id)
    |> foreign_key_constraint(:user_id)
  end

  def scopes, do: @scopes

  @doc """
  Whether this token may still be used.
  """
  def active?(%__MODULE__{revoked_at: revoked}) when not is_nil(revoked), do: false

  def active?(%__MODULE__{expires_at: nil}), do: true

  def active?(%__MODULE__{expires_at: expires_at}) do
    DateTime.compare(expires_at, DateTime.utc_now()) == :gt
  end

  @doc """
  A short word describing the token's current state, for display.
  """
  def status(%__MODULE__{revoked_at: revoked}) when not is_nil(revoked), do: "revoked"

  def status(%__MODULE__{} = token) do
    if active?(token), do: "active", else: "expired"
  end
end
