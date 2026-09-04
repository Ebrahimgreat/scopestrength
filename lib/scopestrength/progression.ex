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

defmodule Scopestrength.Progression do
  @moduledoc """
  Defines the progression methods available to programmes
  and evaluates a completed workout set against a client's
  progression prescription.
  """

  @progressions [
    {"None", "none"},
    {"Dynamic Double Progression", "dynamic_double_progression"}
  ]


  def all, do: @progressions

  @doc """
  Evaluates a completed workout set against the client's progression.

  Each workout set is evaluated independently.

  Returns:

      %{
        status: "progress" | "hold" | "reduce",
        target_weight: number
      }

  Returns `:ignored` when the progression method is not supported
  or the workout set cannot be evaluated.
  """

  def evaluate(method, workout_detail, client_progression)

  def evaluate(
        "dynamic_double_progression",
        %{reps: reps, weight: weight},
        %{
          min_reps: min_reps,
          max_reps: max_reps
        }
      )
      when is_number(reps) and
             is_number(weight) and
             is_integer(min_reps) and
             is_integer(max_reps) do
    status =
      cond do
        reps >= max_reps -> "progress"
        reps < min_reps -> "reduce"
        true -> "hold"
      end

    %{status: status, target_weight: weight}
  end

  def evaluate("none", _workout_detail, _client_progression) do
    :ignored
  end

  def evaluate(_method, _workout_detail, _client_progression) do
    :ignored
  end
end
