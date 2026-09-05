defmodule ScopestrengthWeb.UserSettingsLiveTest do
  use ScopestrengthWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Scopestrength.AccountFixtures
  import Scopestrength.PeopleFixtures

  defp log_in_demo_trainer(%{conn: conn}) do
    trainer = trainer_fixture(%{user: trainer_user_fixture(%{type: "demo"})})
    %{conn: log_in_user(conn, trainer.user), trainer: trainer, user: trainer.user}
  end

  describe "a demo account" do
    setup :log_in_demo_trainer

    test "shows a masked placeholder instead of its real email", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/trainer/settings")
      assert html =~ "Demo account"
      refute html =~ ~r/demo_[a-z0-9]+@scopestrength\.com/
    end

    test "cannot change its name even by firing the event directly", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, ~p"/trainer/settings")
      html = render_click(view, "update_name", %{"name" => "Hacked Name"})

      assert html =~ "can&#39;t change this"
      assert Scopestrength.Account.get_user!(user.id).name == user.name
    end

    test "cannot change its email even by firing the event directly", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, ~p"/trainer/settings")

      html =
        render_click(view, "update_email", %{
          "current_password" => valid_user_password(),
          "user" => %{"email" => "hacked@example.com"}
        })

      assert html =~ "can&#39;t change this"
      assert Scopestrength.Account.get_user!(user.id).email == user.email
    end

    test "cannot change its password even by firing the event directly", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, ~p"/trainer/settings")

      html =
        render_click(view, "update_password", %{
          "current_password" => valid_user_password(),
          "user" => %{"password" => "some new password 123"}
        })

      assert html =~ "can&#39;t change this"
      assert Scopestrength.Account.get_user_by_email_and_password(user.email, valid_user_password())
    end
  end

  describe "a normal account" do
    setup :log_in_trainer

    test "shows its real email and can change name/email/password", %{conn: conn, user: user} do
      {:ok, view, html} = live(conn, ~p"/trainer/settings")
      assert html =~ user.email

      html = render_click(view, "update_name", %{"name" => "New Name"})
      assert html =~ "Name updated"
      assert Scopestrength.Account.get_user!(user.id).name == "New Name"
    end
  end
end
