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

defmodule Scopestrength.Chat.Attachment do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(pending uploaded failed)

  schema "message_attachments" do
    field :file_url, :string
    field :file_name, :string
    field :content_type, :string
    field :file_size, :integer
    field :status, :string, default: "uploaded"
    belongs_to :message, Scopestrength.Chat.Message

    timestamps(type: :utc_datetime)
  end

  @doc "The statuses an attachment may hold."
  def statuses, do: @statuses

  @doc """
  For an attachment whose file is already stored.

  `file_url` is required here: the object exists, so a row without a key would
  be a bug rather than a state.
  """
  def changeset(attachment, attrs) do
    attachment
    |> cast(attrs, [:file_url, :file_name, :content_type, :file_size, :status, :message_id])
    |> validate_required([:file_url, :message_id])
    |> validate_inclusion(:status, @statuses)
  end

  @doc """
  For an attachment whose file has not arrived yet.

  The message is sent the moment it is written, so the row is created before
  the browser finishes uploading. It carries the name and size the client
  reported -- enough to render a placeholder -- and gains its key on
  completion, via `uploaded_changeset/2`.
  """
  def pending_changeset(attachment, attrs) do
    attachment
    |> cast(attrs, [:file_name, :content_type, :file_size, :message_id])
    |> validate_required([:message_id])
    |> put_change(:status, "pending")
  end

  @doc "Marks a pending attachment as stored, recording where it landed."
  def uploaded_changeset(attachment, key) do
    attachment
    |> change(file_url: key, status: "uploaded")
    |> validate_required([:file_url])
  end

  @doc "Marks a pending attachment as never having arrived."
  def failed_changeset(attachment) do
    change(attachment, status: "failed")
  end
end
