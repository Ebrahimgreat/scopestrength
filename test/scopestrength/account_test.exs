defmodule Scopestrength.AccountTest do
  use Scopestrength.DataCase, async: true

  import Scopestrength.AccountFixtures

  alias Scopestrength.Account
  alias Scopestrength.Account.User

  describe "register_user/1" do
    test "requires email and password" do
      {:error, changeset} = Account.register_user(%{})
      assert %{email: ["can't be blank"], password: ["can't be blank"]} = errors_on(changeset)
    end

    test "rejects a malformed email and a short password" do
      {:error, changeset} = Account.register_user(%{email: "nope", password: "short"})
      assert "must have the @ sign and no spaces" in errors_on(changeset).email
      assert "should be at least 12 character(s)" in errors_on(changeset).password
    end

    test "rejects a duplicate email regardless of case" do
      %{email: email} = user_fixture()
      {:error, changeset} = Account.register_user(%{email: String.upcase(email), password: valid_user_password()})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "stores a hashed password and the role" do
      email = unique_user_email()
      {:ok, user} = Account.register_user(%{email: email, password: valid_user_password(), role: "client", name: "Sam"})
      assert user.email == email
      assert user.role == "client"
      assert user.name == "Sam"
      assert is_binary(user.hashed_password)
      assert is_nil(user.password)
    end
  end

  describe "lookups" do
    test "get_user_by_email/1" do
      user = user_fixture()
      assert %User{id: id} = Account.get_user_by_email(user.email)
      assert id == user.id
      refute Account.get_user_by_email("missing@example.com")
    end

    test "get_user_by_email_and_password/2 checks the password" do
      user = user_fixture()
      assert %User{} = Account.get_user_by_email_and_password(user.email, valid_user_password())
      refute Account.get_user_by_email_and_password(user.email, "wrong password!!")
      refute Account.get_user_by_email_and_password("missing@example.com", valid_user_password())
    end

    test "get_user!/1 raises for an unknown id" do
      assert_raise Ecto.NoResultsError, fn -> Account.get_user!(-1) end
    end
  end

  describe "session tokens" do
    test "round trip and deletion" do
      user = user_fixture()
      token = Account.generate_user_session_token(user)
      assert %User{id: id} = Account.get_user_by_session_token(token)
      assert id == user.id

      :ok = Account.delete_user_session_token(token)
      refute Account.get_user_by_session_token(token)
    end
  end

  describe "password reset" do
    setup do
      %{user: user_fixture()}
    end

    test "the emailed token resolves to the user and resets the password", %{user: user} do
      token = extract_user_token(fn url -> Account.deliver_user_reset_password_instructions(user, url) end)

      assert %User{id: id} = Account.get_user_by_reset_password_token(token)
      assert id == user.id
      refute Account.get_user_by_reset_password_token("garbage")

      {:ok, updated} =
        Account.reset_user_password(user, %{password: "brand new password", password_confirmation: "brand new password"})

      assert Account.get_user_by_email_and_password(user.email, "brand new password")
      assert updated.id == user.id
      refute Account.get_user_by_reset_password_token(token)
    end

    test "rejects mismatched confirmation", %{user: user} do
      {:error, changeset} = Account.reset_user_password(user, %{password: "brand new password", password_confirmation: "other"})
      assert "does not match password" in errors_on(changeset).password_confirmation
    end
  end

  describe "update_user_password/3" do
    test "requires the current password" do
      user = user_fixture()
      {:error, changeset} = Account.update_user_password(user, "wrong", %{password: "brand new password"})
      assert "is not valid" in errors_on(changeset).current_password

      {:ok, updated} = Account.update_user_password(user, valid_user_password(), %{password: "brand new password"})
      assert updated.id == user.id
      assert Account.get_user_by_email_and_password(user.email, "brand new password")
    end
  end

  describe "confirmation" do
    test "confirm_user/1 with the emailed token sets confirmed_at" do
      user = user_fixture()
      token = extract_user_token(fn url -> Account.deliver_user_confirmation_instructions(user, url) end)

      {:ok, confirmed} = Account.confirm_user(token)
      assert confirmed.confirmed_at
      assert :error = Account.confirm_user(token)
      assert {:error, :already_confirmed} = Account.deliver_user_confirmation_instructions(confirmed, & &1)
    end
  end

  describe "profile updates" do
    test "update_name/2 and update_role/2" do
      user = user_fixture()
      {:ok, user} = Account.update_name(user, %{name: "New Name"})
      assert user.name == "New Name"
      {:ok, user} = Account.update_role(user, %{role: "client"})
      assert user.role == "client"
    end

    test "apply_user_email/3 validates the current password and email change" do
      user = user_fixture()
      {:error, changeset} = Account.apply_user_email(user, "wrong", %{email: unique_user_email()})
      assert "is not valid" in errors_on(changeset).current_password

      {:error, changeset} = Account.apply_user_email(user, valid_user_password(), %{email: user.email})
      assert "did not change" in errors_on(changeset).email

      new_email = unique_user_email()
      {:ok, applied} = Account.apply_user_email(user, valid_user_password(), %{email: new_email})
      assert applied.email == new_email
      assert Repo.get!(User, user.id).email == user.email
    end
  end
end
