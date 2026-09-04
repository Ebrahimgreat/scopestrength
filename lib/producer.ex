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

defmodule Producer do
  use GenStage
  def start_link(sentence \\ "") do
    GenStage.start(__MODULE__, sentence, name: __MODULE__)
  end
  def init(inital_state) do
    {:producer, inital_state}
  end
  def handle_demand(demand, state) do
    IO.inspect("Demand: #{demand}, state: #{state}", label: "STATE")
    letters = state|> String.graphemes()
    letters_to_consume = Enum.take(letters, demand)
    sentence_left = String.slice(state, demand, length(letters))
    {:noreply, letters_to_consume, sentence_left}

  end

end
