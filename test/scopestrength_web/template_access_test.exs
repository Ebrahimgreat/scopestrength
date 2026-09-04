defmodule ScopestrengthWeb.TemplateAccessTest do
  use Scopestrength.DataCase, async: true

  import Scopestrength.AccountFixtures
  import Scopestrength.ProgrammesFixtures

  alias ScopestrengthWeb.TemplateAccess

  test "only the programme owner may open a template" do
    owner = trainer_user_fixture()
    other = trainer_user_fixture()
    %{template: template} = full_programme_fixture(%{user_id: owner.id})

    assert TemplateAccess.owned_template?(template.id, owner.id)
    assert TemplateAccess.owned_template?(to_string(template.id), owner.id)
    refute TemplateAccess.owned_template?(template.id, other.id)
  end

  test "unknown or malformed ids are refused" do
    user = trainer_user_fixture()
    refute TemplateAccess.owned_template?(-1, user.id)
    refute TemplateAccess.owned_template?("abc", user.id)
    refute TemplateAccess.owned_template?(nil, user.id)
  end
end
