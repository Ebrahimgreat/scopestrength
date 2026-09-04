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

defmodule Scopestrength.WorkoutTracker do

 @spec programme(%{:date => any(), :exercises => any(), optional(any()) => any()}) ::
         :ok | {:error, atom()}
 def programme(%{ name: name, date: date, exercises: exercises}) do
  case File.open("workout.txt",[:write, :utf8]) do
    {:ok, file}->
      IO.puts(file, "Workout created by : #{name}")
      IO.puts(file, "Workout Date, #{date}")
    Enum.each(exercises, fn x->Enum.each(x.workout, fn set->IO.puts(file, "Exercise: #{x.name}\n Set: #{set.set}, Weight: #{set.weight}, Reps: #{set.reps}, volume: #{set.reps * set.weight}")end)end)
    totalWeight = exercises|> Enum.flat_map(fn x-> x.workout end)|> Enum.map(fn workout-> workout.weight end)|>Enum.sum()
   IO.puts(file,"Total Exercises: #{length(exercises)}")
    IO.puts(file, " Workout Volume:  #{totalWeight}")
    File.close(file)
    {:error, reason}->IO.puts("Error opening the file, #{reason}")
  end


 end

end
