defmodule Crohnjobs.ProgrammesTest do
  use Crohnjobs.DataCase

  alias Crohnjobs.Programmes

  describe "programme" do
    alias Crohnjobs.Programmes.Programme

    import Crohnjobs.ProgrammesFixtures

    @invalid_attrs %{}

    test "list_programme/0 returns all programme" do
      programme = programme_fixture()
      assert Programmes.list_programme() == [programme]
    end

    test "get_programme!/1 returns the programme with given id" do
      programme = programme_fixture()
      assert Programmes.get_programme!(programme.id) == programme
    end

    test "create_programme/1 with valid data creates a programme" do
      valid_attrs = %{}

      assert {:ok, %Programme{} = programme} = Programmes.create_programme(valid_attrs)
    end

    test "create_programme/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Programmes.create_programme(@invalid_attrs)
    end

    test "update_programme/2 with valid data updates the programme" do
      programme = programme_fixture()
      update_attrs = %{}

      assert {:ok, %Programme{} = programme} = Programmes.update_programme(programme, update_attrs)
    end

    test "update_programme/2 with invalid data returns error changeset" do
      programme = programme_fixture()
      assert {:error, %Ecto.Changeset{}} = Programmes.update_programme(programme, @invalid_attrs)
      assert programme == Programmes.get_programme!(programme.id)
    end

    test "delete_programme/1 deletes the programme" do
      programme = programme_fixture()
      assert {:ok, %Programme{}} = Programmes.delete_programme(programme)
      assert_raise Ecto.NoResultsError, fn -> Programmes.get_programme!(programme.id) end
    end

    test "change_programme/1 returns a programme changeset" do
      programme = programme_fixture()
      assert %Ecto.Changeset{} = Programmes.change_programme(programme)
    end
  end

  describe "programme_details" do
    alias Crohnjobs.Programmes.Programme

    import Crohnjobs.ProgrammesFixtures

    @invalid_attrs %{}

    test "list_programme_details/0 returns all programme_details" do
      programme = programme_fixture()
      assert Programmes.list_programme_details() == [programme]
    end

    test "get_programme!/1 returns the programme with given id" do
      programme = programme_fixture()
      assert Programmes.get_programme!(programme.id) == programme
    end

    test "create_programme/1 with valid data creates a programme" do
      valid_attrs = %{}

      assert {:ok, %Programme{} = programme} = Programmes.create_programme(valid_attrs)
    end

    test "create_programme/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Programmes.create_programme(@invalid_attrs)
    end

    test "update_programme/2 with valid data updates the programme" do
      programme = programme_fixture()
      update_attrs = %{}

      assert {:ok, %Programme{} = programme} = Programmes.update_programme(programme, update_attrs)
    end

    test "update_programme/2 with invalid data returns error changeset" do
      programme = programme_fixture()
      assert {:error, %Ecto.Changeset{}} = Programmes.update_programme(programme, @invalid_attrs)
      assert programme == Programmes.get_programme!(programme.id)
    end

    test "delete_programme/1 deletes the programme" do
      programme = programme_fixture()
      assert {:ok, %Programme{}} = Programmes.delete_programme(programme)
      assert_raise Ecto.NoResultsError, fn -> Programmes.get_programme!(programme.id) end
    end

    test "change_programme/1 returns a programme changeset" do
      programme = programme_fixture()
      assert %Ecto.Changeset{} = Programmes.change_programme(programme)
    end
  end

  describe "programme_details" do
    alias Crohnjobs.Programmes.ProgrammeDetails

    import Crohnjobs.ProgrammesFixtures

    @invalid_attrs %{}

    test "list_programme_details/0 returns all programme_details" do
      programme_details = programme_details_fixture()
      assert Programmes.list_programme_details() == [programme_details]
    end

    test "get_programme_details!/1 returns the programme_details with given id" do
      programme_details = programme_details_fixture()
      assert Programmes.get_programme_details!(programme_details.id) == programme_details
    end

    test "create_programme_details/1 with valid data creates a programme_details" do
      valid_attrs = %{}

      assert {:ok, %ProgrammeDetails{} = programme_details} = Programmes.create_programme_details(valid_attrs)
    end

    test "create_programme_details/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Programmes.create_programme_details(@invalid_attrs)
    end

    test "update_programme_details/2 with valid data updates the programme_details" do
      programme_details = programme_details_fixture()
      update_attrs = %{}

      assert {:ok, %ProgrammeDetails{} = programme_details} = Programmes.update_programme_details(programme_details, update_attrs)
    end

    test "update_programme_details/2 with invalid data returns error changeset" do
      programme_details = programme_details_fixture()
      assert {:error, %Ecto.Changeset{}} = Programmes.update_programme_details(programme_details, @invalid_attrs)
      assert programme_details == Programmes.get_programme_details!(programme_details.id)
    end

    test "delete_programme_details/1 deletes the programme_details" do
      programme_details = programme_details_fixture()
      assert {:ok, %ProgrammeDetails{}} = Programmes.delete_programme_details(programme_details)
      assert_raise Ecto.NoResultsError, fn -> Programmes.get_programme_details!(programme_details.id) end
    end

    test "change_programme_details/1 returns a programme_details changeset" do
      programme_details = programme_details_fixture()
      assert %Ecto.Changeset{} = Programmes.change_programme_details(programme_details)
    end
  end

  describe "programme_template" do
    alias Crohnjobs.Programmes.ProgrammeTemplate

    import Crohnjobs.ProgrammesFixtures

    @invalid_attrs %{}

    test "list_programme_template/0 returns all programme_template" do
      programme_template = programme_template_fixture()
      assert Programmes.list_programme_template() == [programme_template]
    end

    test "get_programme_template!/1 returns the programme_template with given id" do
      programme_template = programme_template_fixture()
      assert Programmes.get_programme_template!(programme_template.id) == programme_template
    end

    test "create_programme_template/1 with valid data creates a programme_template" do
      valid_attrs = %{}

      assert {:ok, %ProgrammeTemplate{} = programme_template} = Programmes.create_programme_template(valid_attrs)
    end

    test "create_programme_template/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Programmes.create_programme_template(@invalid_attrs)
    end

    test "update_programme_template/2 with valid data updates the programme_template" do
      programme_template = programme_template_fixture()
      update_attrs = %{}

      assert {:ok, %ProgrammeTemplate{} = programme_template} = Programmes.update_programme_template(programme_template, update_attrs)
    end

    test "update_programme_template/2 with invalid data returns error changeset" do
      programme_template = programme_template_fixture()
      assert {:error, %Ecto.Changeset{}} = Programmes.update_programme_template(programme_template, @invalid_attrs)
      assert programme_template == Programmes.get_programme_template!(programme_template.id)
    end

    test "delete_programme_template/1 deletes the programme_template" do
      programme_template = programme_template_fixture()
      assert {:ok, %ProgrammeTemplate{}} = Programmes.delete_programme_template(programme_template)
      assert_raise Ecto.NoResultsError, fn -> Programmes.get_programme_template!(programme_template.id) end
    end

    test "change_programme_template/1 returns a programme_template changeset" do
      programme_template = programme_template_fixture()
      assert %Ecto.Changeset{} = Programmes.change_programme_template(programme_template)
    end
  end

  describe "programmeuser" do
    alias Crohnjobs.Programmes.ProgrammeUser

    import Crohnjobs.ProgrammesFixtures

    @invalid_attrs %{}

    test "list_programmeuser/0 returns all programmeuser" do
      programme_user = programme_user_fixture()
      assert Programmes.list_programmeuser() == [programme_user]
    end

    test "get_programme_user!/1 returns the programme_user with given id" do
      programme_user = programme_user_fixture()
      assert Programmes.get_programme_user!(programme_user.id) == programme_user
    end

    test "create_programme_user/1 with valid data creates a programme_user" do
      valid_attrs = %{}

      assert {:ok, %ProgrammeUser{} = programme_user} = Programmes.create_programme_user(valid_attrs)
    end

    test "create_programme_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Programmes.create_programme_user(@invalid_attrs)
    end

    test "update_programme_user/2 with valid data updates the programme_user" do
      programme_user = programme_user_fixture()
      update_attrs = %{}

      assert {:ok, %ProgrammeUser{} = programme_user} = Programmes.update_programme_user(programme_user, update_attrs)
    end

    test "update_programme_user/2 with invalid data returns error changeset" do
      programme_user = programme_user_fixture()
      assert {:error, %Ecto.Changeset{}} = Programmes.update_programme_user(programme_user, @invalid_attrs)
      assert programme_user == Programmes.get_programme_user!(programme_user.id)
    end

    test "delete_programme_user/1 deletes the programme_user" do
      programme_user = programme_user_fixture()
      assert {:ok, %ProgrammeUser{}} = Programmes.delete_programme_user(programme_user)
      assert_raise Ecto.NoResultsError, fn -> Programmes.get_programme_user!(programme_user.id) end
    end

    test "change_programme_user/1 returns a programme_user changeset" do
      programme_user = programme_user_fixture()
      assert %Ecto.Changeset{} = Programmes.change_programme_user(programme_user)
    end
  end
end
