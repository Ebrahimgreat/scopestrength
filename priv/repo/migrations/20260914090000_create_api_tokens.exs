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

defmodule Scopestrength.Repo.Migrations.CreateApiTokens do
  use Ecto.Migration

  def change do
    create table(:api_tokens) do
      add :name, :string, null: false
      # Only the hash is stored: a database dump must not yield usable tokens.
      add :token_hash, :binary, null: false
      # A short non-secret prefix, so verification can find the candidate row
      # without querying by the secret itself.
      add :prefix, :string, null: false
      add :scope, :string, null: false, default: "read"
      add :expires_at, :utc_datetime
      add :last_used_at, :utc_datetime
      add :revoked_at, :utc_datetime

      add :client_id, references(:clients, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime, default: fragment("now()"))
    end

    create unique_index(:api_tokens, [:prefix])
    create index(:api_tokens, [:client_id])
  end
end
