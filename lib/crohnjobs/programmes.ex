defmodule Crohnjobs.Programmes do
  @moduledoc """
  The Programmes context.
  """

  import Ecto.Query, warn: false
  alias Crohnjobs.Repo

  alias Crohnjobs.Programmes.Programme

  @doc """
  Returns the list of programme.

  ## Examples

      iex> list_programme()
      [%Programme{}, ...]

  """
  def list_programme do
    Repo.all(Programme)
  end

  @doc """
  Gets a single programme.

  Raises `Ecto.NoResultsError` if the Programme does not exist.

  ## Examples

      iex> get_programme!(123)
      %Programme{}

      iex> get_programme!(456)
      ** (Ecto.NoResultsError)

  """
  def get_programme!(id), do: Repo.get!(Programme, id)




  @doc """
  Creates a programme.

  ## Examples

      iex> create_programme(%{field: value})
      {:ok, %Programme{}}

      iex> create_programme(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_programme(attrs \\ %{}) do
    %Programme{}
    |> Programme.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a programme.

  ## Examples

      iex> update_programme(programme, %{field: new_value})
      {:ok, %Programme{}}

      iex> update_programme(programme, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_programme(%Programme{} = programme, attrs) do
    programme
    |> Programme.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a programme.

  ## Examples

      iex> delete_programme(programme)
      {:ok, %Programme{}}

      iex> delete_programme(programme)
      {:error, %Ecto.Changeset{}}

  """
  def delete_programme(%Programme{} = programme) do
    Repo.delete(programme)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking programme changes.

  ## Examples

      iex> change_programme(programme)
      %Ecto.Changeset{data: %Programme{}}

  """
  def change_programme(%Programme{} = programme, attrs \\ %{}) do
    Programme.changeset(programme, attrs)
  end

  alias Crohnjobs.Programmes.ProgrammeDetails

  @doc """
  Returns the list of programme_details.

  ## Examples

      iex> list_programme_details()
      [%ProgrammeDetails{}, ...]

  """
  def list_programme_details do
    Repo.all(ProgrammeDetails)
  end

  @doc """
  Gets a single programme_details.

  Raises `Ecto.NoResultsError` if the Programme details does not exist.

  ## Examples

      iex> get_programme_details!(123)
      %ProgrammeDetails{}

      iex> get_programme_details!(456)
      ** (Ecto.NoResultsError)

  """
  def get_programme_details!(id), do: Repo.get!(ProgrammeDetails, id)

  @doc """
  Creates a programme_details.

  ## Examples

      iex> create_programme_details(%{field: value})
      {:ok, %ProgrammeDetails{}}

      iex> create_programme_details(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_programme_details(attrs \\ %{}) do
    %ProgrammeDetails{}
    |> ProgrammeDetails.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a programme_details.

  ## Examples

      iex> update_programme_details(programme_details, %{field: new_value})
      {:ok, %ProgrammeDetails{}}

      iex> update_programme_details(programme_details, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_programme_details(%ProgrammeDetails{} = programme_details, attrs) do
    programme_details
    |> ProgrammeDetails.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a programme_details.

  ## Examples

      iex> delete_programme_details(programme_details)
      {:ok, %ProgrammeDetails{}}

      iex> delete_programme_details(programme_details)
      {:error, %Ecto.Changeset{}}

  """
  def delete_programme_details(%ProgrammeDetails{} = programme_details) do
    Repo.delete(programme_details)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking programme_details changes.

  ## Examples

      iex> change_programme_details(programme_details)
      %Ecto.Changeset{data: %ProgrammeDetails{}}

  """
  def change_programme_details(%ProgrammeDetails{} = programme_details, attrs \\ %{}) do
    ProgrammeDetails.changeset(programme_details, attrs)
  end

  alias Crohnjobs.Programmes.ProgrammeTemplate

  @doc """
  Returns the list of programme_template.

  ## Examples

      iex> list_programme_template()
      [%ProgrammeTemplate{}, ...]

  """
  def list_programme_template do
    Repo.all(ProgrammeTemplate)
  end

  @doc """
  Gets a single programme_template.

  Raises `Ecto.NoResultsError` if the Programme template does not exist.

  ## Examples

      iex> get_programme_template!(123)
      %ProgrammeTemplate{}

      iex> get_programme_template!(456)
      ** (Ecto.NoResultsError)

  """
  def get_programme_template!(id), do: Repo.get!(ProgrammeTemplate, id)

  @doc """
  Creates a programme_template.

  ## Examples

      iex> create_programme_template(%{field: value})
      {:ok, %ProgrammeTemplate{}}

      iex> create_programme_template(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_programme_template(attrs \\ %{}) do
    %ProgrammeTemplate{}
    |> ProgrammeTemplate.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a programme_template.

  ## Examples

      iex> update_programme_template(programme_template, %{field: new_value})
      {:ok, %ProgrammeTemplate{}}

      iex> update_programme_template(programme_template, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_programme_template(%ProgrammeTemplate{} = programme_template, attrs) do
    programme_template
    |> ProgrammeTemplate.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a programme_template.

  ## Examples

      iex> delete_programme_template(programme_template)
      {:ok, %ProgrammeTemplate{}}

      iex> delete_programme_template(programme_template)
      {:error, %Ecto.Changeset{}}

  """
  def delete_programme_template(%ProgrammeTemplate{} = programme_template) do
    Repo.delete(programme_template)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking programme_template changes.

  ## Examples

      iex> change_programme_template(programme_template)
      %Ecto.Changeset{data: %ProgrammeTemplate{}}

  """
  def change_programme_template(%ProgrammeTemplate{} = programme_template, attrs \\ %{}) do
    ProgrammeTemplate.changeset(programme_template, attrs)
  end

  alias Crohnjobs.Programmes.ProgrammeUser

  @doc """
  Returns the list of programmeuser.

  ## Examples

      iex> list_programmeuser()
      [%ProgrammeUser{}, ...]

  """
  def list_programmeuser do
    Repo.all(ProgrammeUser)
  end

  @doc """
  Gets a single programme_user.

  Raises `Ecto.NoResultsError` if the Programme user does not exist.

  ## Examples

      iex> get_programme_user!(123)
      %ProgrammeUser{}

      iex> get_programme_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_programme_user!(id), do: Repo.get!(ProgrammeUser, id)

  @doc """
  Creates a programme_user.

  ## Examples

      iex> create_programme_user(%{field: value})
      {:ok, %ProgrammeUser{}}

      iex> create_programme_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_programme_user(attrs \\ %{}) do
    %ProgrammeUser{}
    |> ProgrammeUser.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a programme_user.

  ## Examples

      iex> update_programme_user(programme_user, %{field: new_value})
      {:ok, %ProgrammeUser{}}

      iex> update_programme_user(programme_user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_programme_user(%ProgrammeUser{} = programme_user, attrs) do
    programme_user
    |> ProgrammeUser.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a programme_user.

  ## Examples

      iex> delete_programme_user(programme_user)
      {:ok, %ProgrammeUser{}}

      iex> delete_programme_user(programme_user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_programme_user(%ProgrammeUser{} = programme_user) do
    Repo.delete(programme_user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking programme_user changes.

  ## Examples

      iex> change_programme_user(programme_user)
      %Ecto.Changeset{data: %ProgrammeUser{}}

  """
  def change_programme_user(%ProgrammeUser{} = programme_user, attrs \\ %{}) do
    ProgrammeUser.changeset(programme_user, attrs)
  end
end
