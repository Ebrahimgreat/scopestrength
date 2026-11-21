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

  test "parses complete route ids without raising" do
    assert Params.parse_integer(42) == {:ok, 42}
    assert Params.parse_integer("42") == {:ok, 42}
    assert Params.parse_integer("-7") == {:ok, -7}
  end

  test "rejects malformed route ids" do
    assert Params.parse_integer("42abc") == :error
    assert Params.parse_integer("") == :error
    assert Params.parse_integer(nil) == :error
  end
end
