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

defmodule ScopestrengthWeb.ExercisesLiveTest do
  use ScopestrengthWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Ecto.Query

  alias Scopestrength.Exercises.ExerciseMuscleContribution
  alias Scopestrength.Repo

  defp muscles do
    for name <- ["Chest", "Triceps"] do
      Repo.insert!(%Scopestrength.Exercises.Muscles{name: name})
    end
  end

  defp equipment do
    Repo.insert!(%Scopestrength.Exercises.Equipment{name: "Barbell"})
  end

  describe "a client" do
    setup :log_in_client

    test "can select a secondary muscle", %{conn: conn} do
      [primary, secondary] = muscles()
      {:ok, view, _html} = live(conn, ~p"/client/exercises")

      render_click(view, "openModal", %{})
      render_change(view, "update_primary_muscle", %{"muscle_id" => to_string(primary.id)})
      render_click(view, "toggle_secondary_muscle", %{"id" => to_string(secondary.id)})

      assert render(view) =~ secondary.name
    end

    test "can create a custom exercise with a secondary muscle", %{conn: conn} do
      [primary, secondary] = muscles()
      {:ok, view, _html} = live(conn, ~p"/client/exercises")

      render_click(view, "openModal", %{})
      render_change(view, "update_primary_muscle", %{"muscle_id" => to_string(primary.id)})
      render_click(view, "toggle_secondary_muscle", %{"id" => to_string(secondary.id)})

      render_submit(view, "addExercise", %{
        "exercise" => %{"name" => "Client Row", "is_unilateral" => "false", "equipment_id" => to_string(equipment().id)}
      })

      exercise = Repo.get_by(Scopestrength.Exercises.Exercise, name: "Client Row")
      assert exercise

      roles =
        Repo.all(from c in ExerciseMuscleContribution, where: c.exercise_id == ^exercise.id)
        |> Enum.map(& &1.role)
        |> Enum.sort()

      assert roles == ["primary", "secondary"]
    end

    test "can edit an exercise and change its secondary muscle", %{conn: conn} do
      [primary, secondary] = muscles()
      other = Repo.insert!(%Scopestrength.Exercises.Muscles{name: "Delts"})
      equip = equipment()
      {:ok, view, _html} = live(conn, ~p"/client/exercises")

      render_click(view, "openModal", %{})
      render_change(view, "update_primary_muscle", %{"muscle_id" => to_string(primary.id)})
      render_click(view, "toggle_secondary_muscle", %{"id" => to_string(secondary.id)})

      render_submit(view, "addExercise", %{
        "exercise" => %{
          "name" => "Client Row",
          "is_unilateral" => "false",
          "equipment_id" => to_string(equip.id)
        }
      })

      exercise = Repo.get_by(Scopestrength.Exercises.Exercise, name: "Client Row")

      render_click(view, "editExercise", %{"id" => to_string(exercise.id)})
      render_click(view, "toggle_secondary_muscle", %{"id" => to_string(secondary.id)})
      render_click(view, "toggle_secondary_muscle", %{"id" => to_string(other.id)})

      render_submit(view, "saveExercise", %{
        "exercise" => %{
          "id" => to_string(exercise.id),
          "name" => "Client Row Edited",
          "is_unilateral" => "false",
          "equipment_id" => to_string(equip.id)
        }
      })

      assert Repo.get(Scopestrength.Exercises.Exercise, exercise.id).name == "Client Row Edited"

      contributions =
        Repo.all(from c in ExerciseMuscleContribution, where: c.exercise_id == ^exercise.id)

      secondary_ids =
        contributions |> Enum.filter(&(&1.role == "secondary")) |> Enum.map(& &1.muscle_id)

      assert secondary_ids == [other.id]
      assert Enum.all?(contributions, &is_nil(&1.trainer_id))
    end
  end

  describe "a trainer" do
    setup :log_in_trainer

    test "can create a custom exercise with a secondary muscle", %{conn: conn, trainer: trainer} do
      [primary, secondary] = muscles()
      {:ok, view, _html} = live(conn, ~p"/trainer/exercises")

      render_click(view, "openModal", %{})
      render_change(view, "update_primary_muscle", %{"muscle_id" => to_string(primary.id)})
      render_click(view, "toggle_secondary_muscle", %{"id" => to_string(secondary.id)})

      render_submit(view, "addExercise", %{
        "exercise" => %{"name" => "Trainer Row", "is_unilateral" => "false", "equipment_id" => to_string(equipment().id)}
      })

      exercise = Repo.get_by(Scopestrength.Exercises.Exercise, name: "Trainer Row")
      assert exercise

      contributions =
        Repo.all(from c in ExerciseMuscleContribution, where: c.exercise_id == ^exercise.id)

      assert Enum.map(contributions, & &1.role) |> Enum.sort() == ["primary", "secondary"]
      assert Enum.all?(contributions, &(&1.trainer_id == trainer.id))
    end

    test "keeps the trainer id when editing", %{conn: conn, trainer: trainer} do
      [primary, secondary] = muscles()
      equip = equipment()
      {:ok, view, _html} = live(conn, ~p"/trainer/exercises")

      render_click(view, "openModal", %{})
      render_change(view, "update_primary_muscle", %{"muscle_id" => to_string(primary.id)})
      render_click(view, "toggle_secondary_muscle", %{"id" => to_string(secondary.id)})

      render_submit(view, "addExercise", %{
        "exercise" => %{
          "name" => "Trainer Row",
          "is_unilateral" => "false",
          "equipment_id" => to_string(equip.id)
        }
      })

      exercise = Repo.get_by(Scopestrength.Exercises.Exercise, name: "Trainer Row")

      render_click(view, "editExercise", %{"id" => to_string(exercise.id)})

      render_submit(view, "saveExercise", %{
        "exercise" => %{
          "id" => to_string(exercise.id),
          "name" => "Trainer Row Edited",
          "is_unilateral" => "false",
          "equipment_id" => to_string(equip.id)
        }
      })

      contributions =
        Repo.all(from c in ExerciseMuscleContribution, where: c.exercise_id == ^exercise.id)

      assert contributions != []
      assert Enum.all?(contributions, &(&1.trainer_id == trainer.id))
    end
  end
end
