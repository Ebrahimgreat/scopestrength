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

defmodule Scopestrength.Chat do
  @moduledoc """
  The Chat context.
  """

  import Ecto.Query, warn: false
  alias Scopestrength.Repo

  alias Scopestrength.Chat.Message
  alias Scopestrength.Chat.Attachment

  @doc """
  Returns the list of messages.

  ## Examples

      iex> list_messages()
      [%Message{}, ...]

  """
  def list_messages do
    Repo.all(Message)
  end

  @doc """
  Gets a single message.

  Raises `Ecto.NoResultsError` if the Message does not exist.

  ## Examples

      iex> get_message!(123)
      %Message{}

      iex> get_message!(456)
      ** (Ecto.NoResultsError)

  """
  def get_message!(id), do: Repo.get!(Message, id)

  @doc """
  Creates a message.

  ## Examples

      iex> create_message(%{field: value})
      {:ok, %Message{}}

      iex> create_message(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_message(attrs \\ %{}) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates a message along with any uploaded attachments.

  The message and its attachments are inserted in one transaction, so a
  failed attachment does not leave a message referring to a file that was
  never recorded. `attachments` is the list of maps returned by consuming the
  LiveView uploads -- each carries the storage key in `:file_url`.

  ## Examples

      iex> create_message_with_attachments(%{text: "hi", user_id: 1, room_id: "r"}, [])
      {:ok, %Message{}}

  """
  def create_message_with_attachments(attrs, attachments) do
    attrs = Map.put_new(attrs, :text, "")

    Repo.transaction(fn ->
      case create_message(attrs) do
        {:ok, message} ->
          Enum.each(attachments, fn attachment ->
            %Attachment{}
            |> Attachment.changeset(Map.put(attachment, :message_id, message.id))
            |> Repo.insert!()
          end)

          message

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Creates a message whose files are still uploading.

  The counterpart to `create_message_with_attachments/2`, for the case where
  the browser is sending straight to object storage: the message must appear
  in the thread now, not in thirty seconds, so it is written with one pending
  attachment row per file. Each row is completed by `mark_attachment_uploaded/2`
  when its upload lands, or `mark_attachment_failed/1` when it does not.

  `pending` entries are maps of `%{file_name:, content_type:, file_size:}` --
  what the client reported, which is enough to render a placeholder.

  Returns `{:ok, {message, attachments}}`; the attachments come back in the
  order given so the caller can match them to upload entries.
  """
  def create_message_with_pending_attachments(attrs, pending) do
    attrs = Map.put_new(attrs, :text, "")

    Repo.transaction(fn ->
      case create_message(attrs) do
        {:ok, message} ->
          attachments =
            Enum.map(pending, fn entry ->
              %Attachment{}
              |> Attachment.pending_changeset(Map.put(entry, :message_id, message.id))
              |> Repo.insert!()
            end)

          {message, attachments}

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Creates a message carrying both finished and still-uploading attachments.

  A send can hold either: a small file may already be in object storage while a
  large one is halfway there. Both go on the same message so it appears in the
  thread once, complete with placeholders for whatever has not landed yet.

  Returns `{:ok, {message, pending_rows}}` -- the pending rows in the order
  given, so the caller can map them back to their upload entries.
  """
  def create_message_with_mixed_attachments(attrs, stored, pending) do
    attrs = Map.put_new(attrs, :text, "")

    Repo.transaction(fn ->
      case create_message(attrs) do
        {:ok, message} ->
          Enum.each(stored, fn attachment ->
            %Attachment{}
            |> Attachment.changeset(Map.put(attachment, :message_id, message.id))
            |> Repo.insert!()
          end)

          pending_rows =
            Enum.map(pending, fn entry ->
              %Attachment{}
              |> Attachment.pending_changeset(Map.put(entry, :message_id, message.id))
              |> Repo.insert!()
            end)

          {message, pending_rows}

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  @doc "Records where a pending attachment's file landed."
  def mark_attachment_uploaded(%Attachment{} = attachment, key) do
    attachment
    |> Attachment.uploaded_changeset(key)
    |> Repo.update()
  end

  @doc "Marks a pending attachment as never having arrived."
  def mark_attachment_failed(%Attachment{} = attachment) do
    attachment
    |> Attachment.failed_changeset()
    |> Repo.update()
  end

  @doc "Fetches one attachment, or nil."
  def get_attachment(id), do: Repo.get(Attachment, id)

  @doc """
  Updates a message.

  ## Examples

      iex> update_message(message, %{field: new_value})
      {:ok, %Message{}}

      iex> update_message(message, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_message(%Message{} = message, attrs) do
    message
    |> Message.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a message.

  ## Examples

      iex> delete_message(message)
      {:ok, %Message{}}

      iex> delete_message(message)
      {:error, %Ecto.Changeset{}}

  """
  def delete_message(%Message{} = message) do
    Repo.delete(message)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking message changes.

  ## Examples

      iex> change_message(message)
      %Ecto.Changeset{data: %Message{}}

  """
  def change_message(%Message{} = message, attrs \\ %{}) do
    Message.changeset(message, attrs)
  end
end
