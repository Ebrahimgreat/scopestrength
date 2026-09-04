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

defmodule ScopestrengthWeb.Params do
  @moduledoc """
  Helpers for values arriving in LiveView event params.

  An id reaches a `handle_event/3` as a string when it comes from a
  `phx-value-*` attribute, but as an integer when it is pushed from
  `JS.push/2` with a `value:` map (which is what the `<.confirm>` dialog
  does). Handlers must accept both.
  """

  @doc "Coerces an event param to an integer, whichever form it arrived in."
  @spec to_integer(integer() | String.t()) :: integer()
  def to_integer(value) when is_integer(value), do: value
  def to_integer(value) when is_binary(value), do: String.to_integer(value)
end
