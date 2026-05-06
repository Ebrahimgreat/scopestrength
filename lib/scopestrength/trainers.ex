defmodule Scopestrength.Trainers do
  @moduledoc """
  The Trainers context.
  """

  import Ecto.Query, warn: false
  alias Scopestrength.Repo

  alias Scopestrength.Trainers.Trainer
  alias Scopestrength.Trainers.Certification

  @spec list_trainers() :: any()
  @doc """
  Returns the list of trainers.

  ## Examples

      iex> list_trainers()
      [%Trainer{}, ...]

  """
  def list_trainers do
    Repo.all(Trainer)
  end

  @doc """
  Gets a single trainer.

  Raises `Ecto.NoResultsError` if the Trainer does not exist.

  ## Examples

      iex> get_trainer!(123)
      %Trainer{}

      iex> get_trainer!(456)
      ** (Ecto.NoResultsError)

  """

  def get_trainer_byUserId(user_id) do
    Repo.get_by!(Trainer, user_id: user_id)
  end
  def get_trainer!(id), do: Repo.get!(Trainer, id)

  @doc """
  Creates a trainer.

  ## Examples

      iex> create_trainer(%{field: value})
      {:ok, %Trainer{}}

      iex> create_trainer(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_trainer(attrs \\ %{}) do
    %Trainer{}
    |> Trainer.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a trainer.

  ## Examples

      iex> update_trainer(trainer, %{field: new_value})
      {:ok, %Trainer{}}

      iex> update_trainer(trainer, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_trainer(%Trainer{} = trainer, attrs) do
    trainer
    |> Trainer.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a trainer.

  ## Examples

      iex> delete_trainer(trainer)
      {:ok, %Trainer{}}

      iex> delete_trainer(trainer)
      {:error, %Ecto.Changeset{}}

  """
  def delete_trainer(%Trainer{} = trainer) do
    Repo.delete(trainer)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking trainer changes.

  ## Examples

      iex> change_trainer(trainer)
      %Ecto.Changeset{data: %Trainer{}}

  """
  def change_trainer(%Trainer{} = trainer, attrs \\ %{}) do
    Trainer.changeset(trainer, attrs)
  end

  def list_certifications(trainer_id) do
    Repo.all(from c in Certification, where: c.trainer_id == ^trainer_id, order_by: [desc: c.issued_at])
  end

  def get_certification!(id), do: Repo.get!(Certification, id)

  def create_certification(attrs \\ %{}) do
    %Certification{}
    |> Certification.changeset(attrs)
    |> Repo.insert()
  end

  def update_certification(%Certification{} = cert, attrs) do
    cert
    |> Certification.changeset(attrs)
    |> Repo.update()
  end

  def delete_certification(%Certification{} = cert) do
    Repo.delete(cert)
  end

  def change_certification(%Certification{} = cert, attrs \\ %{}) do
    Certification.changeset(cert, attrs)
  end
end
