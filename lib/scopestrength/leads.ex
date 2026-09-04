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
