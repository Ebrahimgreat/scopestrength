defmodule ScopestrengthWeb.ConfirmTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest
  alias Phoenix.LiveView.JS

  test "renders a trigger that opens a hidden dialog carrying the confirm action" do
    html =
      render_component(&ScopestrengthWeb.CoreComponents.confirm/1,
        id: "delete-invite-7",
        title: "Delete Invite",
        message: "Are you sure?",
        confirm_label: "Delete",
        on_confirm: JS.push("delete_invite", value: %{id: 7}),
        class: "trigger-class",
        inner_block: [%{inner_block: fn _, _ -> "Delete" end, __slot__: :inner_block}]
      )

    assert html =~ ~s(id="delete-invite-7")
    assert html =~ "hidden overflow-y-auto"
    assert html =~ "trigger-class"

    assert html =~ "data-confirm-action"
    assert html =~ "delete_invite"
    assert html =~ "Delete Invite"
    assert html =~ "Are you sure?"

    refute html =~ "data-confirm="
  end
end
