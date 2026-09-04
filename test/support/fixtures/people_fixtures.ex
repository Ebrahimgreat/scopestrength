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

defmodule Scopestrength.PeopleFixtures do
  @moduledoc """
  Test helpers for trainers and clients, the two roles every other record
  hangs off. A client fixture builds its own trainer unless one is given.
  """

  import Scopestrength.AccountFixtures

  alias Scopestrength.{Clients, Repo, Trainers}

  def trainer_fixture(attrs \\ %{}) do
    {user, attrs} = Map.pop(attrs, :user)
    user = user || trainer_user_fixture()

    {:ok, trainer} =
      attrs
      |> Enum.into(%{user_id: user.id, bio: "Coach", specialization: "Strength"})
      |> Trainers.create_trainer()

    Repo.preload(trainer, :user)
  end

  def client_fixture(attrs \\ %{}) do
    {user, attrs} = Map.pop(attrs, :user)
    {trainer, attrs} = Map.pop(attrs, :trainer)
    user = user || client_user_fixture()
    trainer = trainer || trainer_fixture()

    {:ok, client} =
      attrs
      |> Enum.into(%{
        user_id: user.id,
        trainer_id: trainer.id,
        age: 30,
        sex: "male",
        height: "180.0",
        active: true
      })
      |> Clients.create_client()

    client |> Repo.preload([:user, trainer: :user])
  end
end
