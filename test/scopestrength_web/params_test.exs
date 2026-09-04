defmodule ScopestrengthWeb.ParamsTest do
  use ExUnit.Case, async: true

  alias ScopestrengthWeb.Params

  test "accepts ids from JS.push and from phx-value attributes" do
    assert Params.to_integer(42) == 42
    assert Params.to_integer("42") == 42
  end

  test "rejects anything else" do
    assert_raise ArgumentError, fn -> Params.to_integer("abc") end
    assert_raise FunctionClauseError, fn -> Params.to_integer(nil) end
  end
end
