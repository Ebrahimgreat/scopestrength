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

defmodule ScopestrengthWeb.TemplateAccess do
  @moduledoc """
  Ownership check shared by the trainer and client template pages.

  A programme template belongs to a programme, and a programme belongs to the
  user who created it (a trainer, or a client who built their own). Anything
  that takes a template id from the URL must confirm that chain ends at the
  current user before showing or editing the template.
  """

  alias Scopestrength.Programmes.{Programme, ProgrammeTemplate}
  alias Scopestrength.Repo

  @doc "True when `template_id` belongs to a programme owned by `user_id`."
  @spec owned_template?(String.t() | integer() | nil, integer()) :: boolean()
  def owned_template?(template_id, user_id) do
    with {id, ""} <- Integer.parse(to_string(template_id)),
         %ProgrammeTemplate{programme_id: programme_id} <- Repo.get(ProgrammeTemplate, id),
         %Programme{user_id: ^user_id} <- Repo.get(Programme, programme_id) do
      true
    else
      _ -> false
    end
  end
end
