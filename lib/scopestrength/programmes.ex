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

defmodule Scopestrength.Programmes do
  @moduledoc """
  The Programmes context.
  """

  import Ecto.Query, warn: false
  alias Scopestrength.Repo

  alias Scopestrength.Programmes.Programme


 def get_programme_with_template(id) do
   Programme|> Repo.get(id)|>
   Repo.preload(programmeTemplates: [programmeDetails: [exercise: :muscle]])
 end

 @doc """
 Calculates total volume (direct and effective) across all templates in a programme.
 Returns a map of muscle groups with their direct and effective sets.
 """
 def calculate_programme_volume(programme) do
   alias Scopestrength.Exercises.ExerciseMuscleContribution

   exercise_ids =
     programme.programmeTemplates
     |> Enum.flat_map(& &1.programmeDetails)
     |> Enum.map(& &1.exercise_id)
     |> Enum.uniq()

   muscle_contributions =
     Repo.all(from c in ExerciseMuscleContribution, where: c.exercise_id in ^exercise_ids)
     |> Repo.preload(:muscle)

   contributions_by_exercise = Enum.group_by(muscle_contributions, & &1.exercise_id)

   expanded =
     programme.programmeTemplates
     |> Enum.flat_map(fn template ->
       template.programmeDetails
       |> Enum.flat_map(fn detail ->
         sets = String.to_integer(detail.set)
         contributions = Map.get(contributions_by_exercise, detail.exercise_id, [])

         Enum.map(contributions, fn c ->
           {c.muscle.name, c.role, sets * c.multiplier}
         end)
       end)
     end)

   expanded
   |> Enum.group_by(fn {muscle, _role, _volume} -> muscle end)
   |> Enum.map(fn {muscle, rows} ->
     direct_sets =
       rows
       |> Enum.filter(fn {_m, role, _v} -> role == "primary" end)
       |> Enum.map(fn {_m, _r, v} -> v end)
       |> Enum.sum()

     effective_sets =
       rows
       |> Enum.map(fn {_m, _r, v} -> v end)
       |> Enum.sum()

     {muscle, %{direct: direct_sets, effective: effective_sets}}
   end)
   |> Map.new()
 end

  @doc """
  Copies a programme the client has been assigned into their own list.

  `clone_programme/2` is scoped to the owner, which is right for a trainer
  duplicating their own work but wrong here: the programme belongs to the
  trainer, and the client is copying it. Authorisation is the assignment --
  the client may copy a programme that is (or was) assigned to them, and
  nothing else.

  Returns `{:error, :not_assigned}` if it was never assigned to that client.

  ## Examples

      iex> clone_assigned_programme(user_id, client_id, 16)
      {:ok, %Programme{}}

  """
  def clone_assigned_programme(user_id, client_id, programme_id) do
    assigned? =
      Scopestrength.Programmes.ProgrammeUser
      |> where([pu], pu.client_id == ^client_id and pu.programme_id == ^programme_id)
      |> Repo.exists?()

    if assigned? do
      clone_programme(programme_id, owner_id: user_id)
    else
      {:error, :not_assigned}
    end
  end

  def clone_programme(user_id, programme_id) when is_integer(programme_id) do
    do_clone_programme(Repo.get_by!(Programme, id: programme_id, user_id: user_id), user_id)
  end

  def clone_programme(programme_id, owner_id: owner_id) do
    do_clone_programme(Repo.get!(Programme, programme_id), owner_id)
  end

  defp do_clone_programme(programme, owner_id) do

    programme =
      programme
      |> Repo.preload(programmeTemplates: :programmeDetails)

    Repo.transaction(fn ->
      {:ok, new_programme} =
        create_programme(%{
          name: "#{programme.name} (copy)",
          description: programme.description,
          progression_method: programme.progression_method,
          user_id: owner_id
        })

      now = DateTime.utc_now() |> DateTime.truncate(:second)

      template_rows =
        Enum.map(programme.programmeTemplates, fn template ->
          %{
            name: template.name,
            programme_id: new_programme.id,
            inserted_at: now,
            updated_at: now
          }
        end)

      template_count = length(template_rows)

      {^template_count, inserted_templates} =
        Repo.insert_all(Scopestrength.Programmes.ProgrammeTemplate, template_rows,
          returning: [:id]
        )

      detail_rows =
        Enum.zip(programme.programmeTemplates, inserted_templates)
        |> Enum.flat_map(fn {old_template, new_template} ->
          Enum.map(old_template.programmeDetails, fn detail ->
            %{
              set: detail.set,
              reps: detail.reps,
              rir: detail.rir,
              min_reps: detail.min_reps,
              max_reps: detail.max_reps,
              exercise_id: detail.exercise_id,
              programme_template_id: new_template.id,
              inserted_at: now,
              updated_at: now
            }
          end)
        end)

      detail_count = length(detail_rows)

      {^detail_count, _} =
        Repo.insert_all(Scopestrength.Programmes.ProgrammeDetails, detail_rows)

      new_programme
    end)
  end

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
  Lists only the programmes belonging to `user_id`.

  Filters in SQL rather than loading every programme in the table and
  rejecting in Elixir.
  """
  def list_user_programmes(user_id) do
    Repo.all(from p in Programme, where: p.user_id == ^user_id)
  end

  @doc """
  Fetches a programme only if it belongs to `user_id`.

  Raises `Ecto.NoResultsError` when the programme does not exist OR belongs
  to another user — the two cases are deliberately indistinguishable.
  """
  def get_user_programme!(user_id, id) do
    Repo.get_by!(Programme, id: id, user_id: user_id)
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

  alias Scopestrength.Programmes.ProgrammeDetails

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

  def get_programme_detail_with_exericse!(id) do
    Repo.get!(ProgrammeDetails,id)
    |> Repo.preload(:exercise)
  end

  @spec create_programme_details() :: any()
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

  alias Scopestrength.Programmes.ProgrammeTemplate

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

  alias Scopestrength.Programmes.ProgrammeUser

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
  Returns the ids of clients currently on a programme, as a MapSet.

  Only active assignments count. Moving a client to another programme flips
  the old row to `is_active: false` and inserts a new one, so inactive rows
  are history -- a client moved off this programme must be offered again.

  ## Examples

      iex> assigned_client_ids(16)
      #MapSet<[3, 7]>

  """
  def assigned_client_ids(programme_id) do
    ProgrammeUser
    |> where([pu], pu.programme_id == ^programme_id and pu.is_active == true)
    |> select([pu], pu.client_id)
    |> Repo.all()
    |> MapSet.new()
  end

  @doc """
  Takes a client off a programme, leaving them on nothing.

  The counterpart to `assign_client_to_programme/2`, which always leaves the
  client on something. This is the case that one cannot express: a client who
  is paused, injured or between blocks. The row is demoted rather than deleted,
  so their history on the programme survives.

  Returns `{:ok, count}` -- 0 when the client was not on this programme.

  ## Examples

      iex> unassign_client_from_programme(16, 3)
      {:ok, 1}

  """
  def unassign_client_from_programme(programme_id, client_id) do
    {count, _} =
      from(pu in ProgrammeUser,
        where:
          pu.programme_id == ^programme_id and
            pu.client_id == ^client_id and
            pu.is_active == true
      )
      |> Repo.update_all(set: [is_active: false, updated_at: DateTime.utc_now(:second)])

    {:ok, count}
  end

  @doc """
  Moves a client onto a programme, replacing whatever they were on.

  A client is only ever on one programme at a time, so any active assignment
  is demoted to history before the new row is inserted -- the two happen in a
  transaction, and a partial unique index on `(client_id) where is_active`
  backs the invariant up in the database.

  ## Examples

      iex> assign_client_to_programme(16, 3)
      {:ok, %ProgrammeUser{}}

  """
  def assign_client_to_programme(programme_id, client_id) do
    Repo.transaction(fn ->
      from(pu in ProgrammeUser,
        where: pu.client_id == ^client_id and pu.is_active == true
      )
      |> Repo.update_all(set: [is_active: false, updated_at: DateTime.utc_now(:second)])

      %ProgrammeUser{}
      |> ProgrammeUser.changeset(%{
        programme_id: programme_id,
        client_id: client_id,
        is_active: true
      })
      |> Repo.insert()
      |> case do
        {:ok, programme_user} -> programme_user
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

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
