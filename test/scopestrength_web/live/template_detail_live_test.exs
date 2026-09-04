defmodule ScopestrengthWeb.TemplateDetailLiveTest do
  use ScopestrengthWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Scopestrength.ExercisesFixtures
  import Scopestrength.ProgrammesFixtures

  alias Scopestrength.Programmes

  describe "trainer" do
    setup :log_in_trainer

    test "can open and edit their own template", %{conn: conn, user: user} do
      %{programme: programme, template: template, details: details} = full_programme_fixture(%{user_id: user.id})
      {:ok, view, html} = live(conn, ~p"/trainer/programmes/#{programme.id}/template/#{template.id}/details")
      assert html =~ "Template Builder"

      exercise = exercise_fixture(%{name: "Row"})
      assert render_click(view, "addExercise", %{"id" => to_string(exercise.id)}) =~ "Row"

      render_click(view, "deleteExercise", %{"id" => details.id})
      assert_raise Ecto.NoResultsError, fn -> Programmes.get_programme_details!(details.id) end
    end

    test "cannot open another trainer's template", %{conn: conn} do
      %{programme: programme, template: template} = full_programme_fixture()

      assert {:error, {:redirect, %{to: "/trainer/programmes", flash: %{"error" => "Template not found"}}}} =
               live(conn, ~p"/trainer/programmes/#{programme.id}/template/#{template.id}/details")
    end
  end

  describe "client" do
    setup :log_in_client

    test "cannot open the trainer's template", %{conn: conn} do
      %{programme: programme, template: template} = full_programme_fixture()

      assert {:error, {:redirect, %{to: "/client/programmes"}}} =
               live(conn, ~p"/client/programmes/#{programme.id}/template/#{template.id}/details")
    end

    test "can open their own copy", %{conn: conn, user: user} do
      %{programme: programme, template: template} = full_programme_fixture(%{user_id: user.id})
      assert {:ok, _view, html} = live(conn, ~p"/client/programmes/#{programme.id}/template/#{template.id}/details")
      assert html =~ "Template Exercise Builder"
    end
  end
end
