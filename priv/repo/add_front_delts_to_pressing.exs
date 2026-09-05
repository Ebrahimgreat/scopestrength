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

alias Scopestrength.Repo
alias Scopestrength.Exercises.{Exercise, Muscles, ExerciseMuscleContribution}
import Ecto.Query

front_delts_id = Repo.one!(from m in Muscles, where: m.name == "Front Delts", select: m.id)

name_patterns = [
  "%bench press%",
  "%chest press%",
  "%incline press%",
  "%decline press%",
  "%chest fly%",
  "%pec fly%",
  "%pec deck%",
  "%chest dip%",
  "%push up%",
  "%push-up%"
]

plain_terms = Enum.map(name_patterns, &String.trim(&1, "%"))

candidates =
  from(e in Exercise, where: e.is_custom == false)
  |> Repo.all()
  |> Enum.filter(fn e ->
    downcased = String.downcase(e.name)
    Enum.any?(plain_terms, &String.contains?(downcased, &1))
  end)

already_tagged =
  MapSet.new(
    Repo.all(
      from emc in ExerciseMuscleContribution,
        where: emc.muscle_id == ^front_delts_id,
        select: emc.exercise_id
    )
  )

to_tag = Enum.reject(candidates, &MapSet.member?(already_tagged, &1.id))

Enum.each(to_tag, fn exercise ->
  %ExerciseMuscleContribution{}
  |> ExerciseMuscleContribution.changeset(%{
    exercise_id: exercise.id,
    muscle_id: front_delts_id,
    role: "secondary",
    multiplier: 0.5
  })
  |> Repo.insert!()
end)

IO.puts("Tagged #{length(to_tag)} exercises with Front Delts (secondary, 0.5).")
IO.puts("#{length(candidates) - length(to_tag)} matching exercises already had it.")
