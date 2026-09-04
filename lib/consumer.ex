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

defmodule Consumer do
  use GenStage
  require Logger
  alias Producer
  def start_link(args \\ "") do
    GenStage.start_link(__MODULE__, args)
  end
  def init(args) do
    Logger.info("init consuming")
    subscribe_options = [{Producer, min_demand: 0, max_demand: 10}]
    {:consumer, args, subscribe_to: subscribe_options}
  end
  def handle_events(events, _from, state) do
    Logger.info("Consumer State: #{state}")
    words = Enum.join(events)
    sentence = state <> words
    Logger.info("Final Stage: #{sentence}")
    {:noreply, [], sentence}

  end

end
