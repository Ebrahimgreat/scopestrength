defmodule Scopestrength.ProgrammesTest do
  use Scopestrength.DataCase, async: true

  import Scopestrength.AccountFixtures
  import Scopestrength.ExercisesFixtures
  import Scopestrength.PeopleFixtures
  import Scopestrength.ProgrammesFixtures

  alias Scopestrength.Programmes
  alias Scopestrength.Programmes.{Programme, ProgrammeUser}

  describe "programmes" do
    test "are scoped to their owner" do
      owner = trainer_user_fixture()
      other = trainer_user_fixture()
      mine = programme_fixture(%{user_id: owner.id})
      theirs = programme_fixture(%{user_id: other.id})

      assert Enum.map(Programmes.list_user_programmes(owner.id), & &1.id) == [mine.id]
      assert Programmes.get_user_programme!(owner.id, mine.id).id == mine.id
      assert_raise Ecto.NoResultsError, fn -> Programmes.get_user_programme!(owner.id, theirs.id) end
    end

    test "update and delete" do
      programme = programme_fixture()
      {:ok, programme} = Programmes.update_programme(programme, %{name: "Renamed", progression_method: "none"})
      assert programme.name == "Renamed"
      assert programme.progression_method == "none"
      {:ok, _} = Programmes.delete_programme(programme)
      assert_raise Ecto.NoResultsError, fn -> Programmes.get_programme!(programme.id) end
    end
  end

  describe "templates and details" do
    test "a template belongs to a programme and holds exercises" do
      %{programme: programme, template: template, details: details, exercise: exercise} = full_programme_fixture()

      assert template.programme_id == programme.id
      assert details.exercise_id == exercise.id
      assert Programmes.get_programme_detail_with_exericse!(details.id).exercise.id == exercise.id

      loaded = Programmes.get_programme_with_template(programme.id)
      assert [%{programmeDetails: [%{id: id}]}] = loaded.programmeTemplates
      assert id == details.id
    end

    test "details update rep range and delete" do
      details = programme_details_fixture()
      {:ok, details} = Programmes.update_programme_details(details, %{min_reps: 6, max_reps: 10, set: "4"})
      assert details.min_reps == 6
      assert details.set == "4"
      {:ok, _} = Programmes.delete_programme_details(details)
      assert_raise Ecto.NoResultsError, fn -> Programmes.get_programme_details!(details.id) end
    end

    test "template update and delete" do
      template = programme_template_fixture()
      {:ok, template} = Programmes.update_programme_template(template, %{name: "Push"})
      assert Programmes.get_programme_template!(template.id).name == "Push"
      {:ok, _} = Programmes.delete_programme_template(template)
    end
  end

  describe "assignment" do
    test "a client has one active programme at a time" do
      client = client_fixture()
      first = programme_fixture()
      second = programme_fixture()

      {:ok, %ProgrammeUser{is_active: true}} = Programmes.assign_client_to_programme(first.id, client.id)
      assert MapSet.to_list(Programmes.assigned_client_ids(first.id)) == [client.id]

      {:ok, _} = Programmes.assign_client_to_programme(second.id, client.id)
      assert MapSet.to_list(Programmes.assigned_client_ids(first.id)) == []
      assert MapSet.to_list(Programmes.assigned_client_ids(second.id)) == [client.id]

      active = Repo.get_by!(ProgrammeUser, client_id: client.id, is_active: true)
      assert active.programme_id == second.id
    end

    test "unassign deactivates and reports the count" do
      client = client_fixture()
      programme = programme_fixture()
      {:ok, _} = Programmes.assign_client_to_programme(programme.id, client.id)

      assert {:ok, 1} = Programmes.unassign_client_from_programme(programme.id, client.id)
      assert {:ok, 0} = Programmes.unassign_client_from_programme(programme.id, client.id)
      assert MapSet.to_list(Programmes.assigned_client_ids(programme.id)) == []
    end
  end

  describe "cloning" do
    test "clone_programme/2 copies templates and details to the owner" do
      owner = trainer_user_fixture()
      %{programme: programme, exercise: exercise} = full_programme_fixture(%{user_id: owner.id, name: "PPL"})

      {:ok, copy} = Programmes.clone_programme(owner.id, programme.id)
      assert %Programme{} = copy
      assert copy.name == "PPL (copy)"
      assert copy.user_id == owner.id
      assert copy.progression_method == programme.progression_method

      loaded = Programmes.get_programme_with_template(copy.id)
      assert [%{programmeDetails: [detail]}] = loaded.programmeTemplates
      assert detail.exercise_id == exercise.id
      assert detail.min_reps == 8
    end

    test "clone_programme/2 refuses another user's programme" do
      other = trainer_user_fixture()
      programme = programme_fixture()
      assert_raise Ecto.NoResultsError, fn -> Programmes.clone_programme(other.id, programme.id) end
    end

    test "clone_assigned_programme/3 only copies a programme the client is on" do
      client = client_fixture()
      %{programme: programme} = full_programme_fixture()

      assert {:error, :not_assigned} =
               Programmes.clone_assigned_programme(client.user_id, client.id, programme.id)

      {:ok, _} = Programmes.assign_client_to_programme(programme.id, client.id)
      {:ok, copy} = Programmes.clone_assigned_programme(client.user_id, client.id, programme.id)
      assert copy.user_id == client.user_id
      assert Enum.map(Programmes.list_user_programmes(client.user_id), & &1.id) == [copy.id]
    end
  end

  test "exercise_fixture exercises can be reused across programmes" do
    exercise = exercise_fixture()
    a = full_programme_fixture(%{exercise: exercise})
    b = full_programme_fixture(%{exercise: exercise})
    assert a.details.exercise_id == b.details.exercise_id
  end
end
