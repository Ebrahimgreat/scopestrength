defmodule Scopestrength.Storage.Access do
  import Ecto.Query

  alias Scopestrength.Chat.Attachment
  alias Scopestrength.Clients.Client
  alias Scopestrength.ProgressPhotos.ProgressPhoto
  alias Scopestrength.Repo
  alias Scopestrength.Trainers.Trainer

  def authorized?(key, %{id: user_id, role: role}) when is_binary(key) do
    case key do
      "progress_photos/" <> _ -> progress_photo_authorized?(key, user_id, role)
      "profile_pictures/" <> _ -> profile_picture_authorized?(key, user_id, role)
      "chat/" <> _ -> attachment_authorized?(key, user_id, role)
      _ -> false
    end
  end

  def authorized?(_key, _user), do: false

  defp progress_photo_authorized?(key, user_id, "client") do
    keys = stored_keys(key)

    Repo.exists?(
      from p in ProgressPhoto,
        join: c in Client,
        on: c.id == p.client_id,
        where: p.photo_url in ^keys and c.user_id == ^user_id
    )
  end

  defp progress_photo_authorized?(key, user_id, "trainer") do
    keys = stored_keys(key)

    Repo.exists?(
      from p in ProgressPhoto,
        join: c in Client,
        on: c.id == p.client_id,
        join: t in Trainer,
        on: t.id == c.trainer_id,
        where: p.photo_url in ^keys and t.user_id == ^user_id
    )
  end

  defp progress_photo_authorized?(_key, _user_id, _role), do: false

  defp profile_picture_authorized?(key, user_id, "client") do
    keys = stored_keys(key)

    Repo.exists?(from c in Client, where: c.profile_picture_url in ^keys and c.user_id == ^user_id) or
      Repo.exists?(
        from t in Trainer,
          join: c in Client,
          on: c.trainer_id == t.id,
          where: t.profile_picture_url in ^keys and c.user_id == ^user_id
      )
  end

  defp profile_picture_authorized?(key, user_id, "trainer") do
    keys = stored_keys(key)

    Repo.exists?(
      from c in Client,
        join: t in Trainer,
        on: t.id == c.trainer_id,
        where: c.profile_picture_url in ^keys and t.user_id == ^user_id
    ) or
      Repo.exists?(from t in Trainer, where: t.profile_picture_url in ^keys and t.user_id == ^user_id)
  end

  defp profile_picture_authorized?(_key, _user_id, _role), do: false

  defp attachment_authorized?(key, user_id, role) do
    keys = stored_keys(key)

    case Repo.one(
           from a in Attachment,
             join: m in assoc(a, :message),
             where: a.file_url in ^keys,
             select: m.room_id
         ) do
      room_id -> room_authorized?(room_id, user_id, role)
      nil -> false
    end
  end

  defp room_authorized?(room_id, user_id, "client") do
    with {client_id, ""} <- Integer.parse(room_id) do
      Repo.exists?(from c in Client, where: c.id == ^client_id and c.user_id == ^user_id)
    else
      _ -> false
    end
  end

  defp room_authorized?(room_id, user_id, "trainer") do
    with {client_id, ""} <- Integer.parse(room_id) do
      Repo.exists?(
        from c in Client,
          join: t in Trainer,
          on: t.id == c.trainer_id,
          where: c.id == ^client_id and t.user_id == ^user_id
      )
    else
      _ -> false
    end
  end

  defp room_authorized?(_room_id, _user_id, _role), do: false

  defp stored_keys(key), do: [key, "/uploads/" <> key]
end
