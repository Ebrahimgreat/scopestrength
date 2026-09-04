defmodule Scopestrength.InvitesTest do
  use Scopestrength.DataCase, async: true

  import Scopestrength.PeopleFixtures
  import Scopestrength.RecordsFixtures

  alias Scopestrength.Invites

  test "create_invite/2 makes an 8 character code and lower-cases the email" do
    trainer = trainer_fixture()
    {:ok, invite} = Invites.create_invite(trainer.id, "Person@Example.com")
    assert String.length(invite.code) == 8
    assert invite.email == "person@example.com"
    refute invite.used
    assert Enum.map(Invites.list_invites_for_trainer(trainer.id), & &1.id) == [invite.id]
  end

  test "check_invite/2 reports each failure without redeeming" do
    trainer = trainer_fixture()
    invite = invite_fixture(%{trainer_id: trainer.id, email: "person@example.com"})

    assert {:error, :invalid_code} = Invites.check_invite("NOPE1234", "person@example.com")
    assert {:error, :email_mismatch} = Invites.check_invite(invite.code, "other@example.com")
    assert {:ok, trainer_id, name} = Invites.check_invite(invite.code, "PERSON@example.com")
    assert trainer_id == trainer.id
    assert name == trainer.user.name
    refute Repo.reload!(invite).used
  end

  test "redeem_invite/2 marks the invite used exactly once" do
    trainer = trainer_fixture()
    invite = invite_fixture(%{trainer_id: trainer.id, email: "person@example.com"})

    assert {:ok, trainer_id} = Invites.redeem_invite(invite.code, "person@example.com")
    assert trainer_id == trainer.id
    assert {:error, :already_used} = Invites.redeem_invite(invite.code, "person@example.com")
    assert {:error, :already_used} = Invites.check_invite(invite.code, "person@example.com")
  end

  test "link_client_to_trainer/2 moves the client" do
    client = client_fixture()
    new_trainer = trainer_fixture()
    {:ok, updated} = Invites.link_client_to_trainer(client.id, new_trainer.id)
    assert updated.trainer_id == new_trainer.id
  end

  test "delete_invite/2 only removes the trainer's own unused invites" do
    trainer = trainer_fixture()
    other = trainer_fixture()
    invite = invite_fixture(%{trainer_id: trainer.id})

    assert {:error, :not_found} = Invites.delete_invite(invite.id, other.id)
    assert {:ok, _} = Invites.delete_invite(invite.id, trainer.id)

    used = invite_fixture(%{trainer_id: trainer.id, email: "used@example.com"})
    {:ok, _} = Invites.redeem_invite(used.code, "used@example.com")
    assert {:error, :not_found} = Invites.delete_invite(used.id, trainer.id)
  end
end
