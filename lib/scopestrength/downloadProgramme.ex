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

defmodule Scopestrength.DownloadProgramme do
  def downloadProgramme(%{programme: programme}) do
    programme_name = programme.name
    programme_description = programme.description

    programme_templates =
      Enum.map(programme.programmeTemplates, fn template ->
        %{
          template_name: template.name,
          exercises: Enum.map(template.programmeDetails, fn detail ->
            %{
              name: detail.exercise.name,
              reps: detail.reps,
              set: detail.set
            }
          end)
        }
      end)

    case File.open("programme.txt", [:write, :utf8]) do
      {:ok, file} ->
        IO.puts(file, "Programme Name: #{programme_name}")
        IO.puts(file, "Programme Description: #{programme_description}")
        IO.puts(file, "")

        Enum.each(programme_templates, fn template ->
          IO.puts(file, "Template : #{template.template_name}")
          Enum.each(template.exercises, fn exercise ->
            IO.puts(
              file,
              "  Exercise: #{exercise.name}, Set: #{exercise.set}, Reps: #{exercise.reps}"
            )
          end)

          IO.puts(file, "")
        end)

        File.close(file)

      {:error, reason} ->
        IO.inspect(reason, label: "Error opening file")
    end
  end
end
