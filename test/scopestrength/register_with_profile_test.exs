defmodule Scopestrength.RegisterWithProfileTest do
  use Scopestrength.DataCase, async: true

  alias Scopestrength.{Account, Repo}
  alias Scopestrength.Account.User
  alias Scopestrength.Clients.Client
  alias Scopestrength.Trainers.Trainer

  defp attrs(role, extra \\ %{}) do
    Map.merge(
      %{
        email: "reg#{System.unique_integer([:positive])}@example.com",
        password: "averylongpassword1",
        name: "Reg",
        role: role
      },
      extra
    )
  end

  test "a trainer gets a trainers row" do
    {:ok, %{user: user, profile: profile}} =
      Account.register_user_with_profile(attrs("trainer"))

    assert %Trainer{} = profile
    assert profile.user_id == user.id
    assert Repo.get_by(Trainer, user_id: user.id)
  end

  test "a client gets a clients row" do
    {:ok, %{user: user, profile: profile}} =
      Account.register_user_with_profile(attrs("client"))

    assert %Client{} = profile
    assert profile.user_id == user.id
    assert is_nil(profile.trainer_id)
  end

  test "a client can be linked to a trainer at registration" do
    {:ok, %{profile: trainer}} = Account.register_user_with_profile(attrs("trainer"))

    {:ok, %{profile: client}} =
      Account.register_user_with_profile(attrs("client"), trainer_id: trainer.id)

    assert client.trainer_id == trainer.id
  end

  test "an invalid password creates no user at all" do
    before = Repo.aggregate(User, :count)
    assert {:error, %Ecto.Changeset{}} = Account.register_user_with_profile(attrs("client", %{password: "short"}))
    assert Repo.aggregate(User, :count) == before
  end

  test "an unknown role rolls the user back instead of leaving an orphan" do
    before = Repo.aggregate(User, :count)
    assert {:error, reason} = Account.register_user_with_profile(attrs("wizard"))
    assert reason =~ "unknown role"
    assert Repo.aggregate(User, :count) == before
  end
end
