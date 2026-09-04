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

defmodule Scopestrength.RecordsFixtures do
  @moduledoc """
  Test helpers for the smaller per-client records: notes, weights, progress
  photos, notifications, chat messages and invites.
  """

  import Scopestrength.AccountFixtures
  import Scopestrength.PeopleFixtures

  alias Scopestrength.{Chat, ClientNote, ClientWeight, Invites, Notifications, ProgressPhotos}

  def client_note_fixture(attrs \\ %{}) do
    attrs = Map.new(attrs)
    client_id = attrs[:client_id] || client_fixture().id

    {:ok, note} =
      attrs
      |> Enum.into(%{client_id: client_id, date: Date.utc_today(), notes: "Felt strong"})
      |> ClientNote.create_client_notes()

    note
  end

  def client_weight_fixture(attrs \\ %{}) do
    attrs = Map.new(attrs)
    client_id = attrs[:client_id] || client_fixture().id

    {:ok, weight} =
      attrs
      |> Enum.into(%{client_id: client_id, date: Date.utc_today(), weight: "80.5"})
      |> ClientWeight.create_client_weights()

    weight
  end

  def progress_photo_fixture(attrs \\ %{}) do
    attrs = Map.new(attrs)
    client_id = attrs[:client_id] || client_fixture().id

    {:ok, photo} =
      attrs
      |> Enum.into(%{
        client_id: client_id,
        date: DateTime.utc_now() |> DateTime.truncate(:second),
        photo_url: "progress_photos/#{System.unique_integer([:positive])}.jpg",
        notes: "Week 1"
      })
      |> ProgressPhotos.create_progress_photo()

    photo
  end

  def notification_fixture(attrs \\ %{}) do
    {:ok, notification} =
      attrs
      |> Enum.into(%{
        actor_id: 1,
        actor_type: "client",
        recipient_id: 1,
        recipient_type: "trainer",
        type: "workout_created",
        data: %{}
      })
      |> Notifications.create_notification()

    notification
  end

  def message_fixture(attrs \\ %{}) do
    attrs = Map.new(attrs)
    user_id = attrs[:user_id] || user_fixture().id

    {:ok, message} =
      attrs
      |> Enum.into(%{user_id: user_id, room_id: "1", text: "hello"})
      |> Chat.create_message()

    message
  end

  def invite_fixture(attrs \\ %{}) do
    attrs = Map.new(attrs)
    trainer_id = attrs[:trainer_id] || trainer_fixture().id
    email = attrs[:email] || unique_user_email()

    {:ok, invite} = Invites.create_invite(trainer_id, email)
    invite
  end
end
