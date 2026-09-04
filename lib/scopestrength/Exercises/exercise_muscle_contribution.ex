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

defmodule Scopestrength.Exercises.ExerciseMuscleContribution do
  use Ecto.Schema
  import Ecto.Changeset

  schema "exercise_muscle_contribution" do
    belongs_to :muscle, Scopestrength.Exercises.Muscles
    belongs_to :exercise, Scopestrength.Exercises.Exercise
    field :role, :string
    field :multiplier, :float
    belongs_to :trainer, Scopestrength.Trainers.Trainer



    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(exercise_muscle_contribution, attrs) do
    exercise_muscle_contribution
    |> cast(attrs, [:muscle_id, :role, :multiplier, :trainer_id, :exercise_id])
    |> validate_required([:muscle_id, :role, :multiplier, :exercise_id])
  end
end
