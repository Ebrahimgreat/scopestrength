defmodule Scopestrength.ProgressionTest do
  use ExUnit.Case, async: true

  alias Scopestrength.Progression

  @range %{min_reps: 8, max_reps: 12}

  describe "dynamic double progression" do
    test "progresses at or above the top of the range" do
      assert %{status: "progress", target_weight: 60.0} =
               Progression.evaluate("dynamic_double_progression", %{reps: 12.0, weight: 60.0}, @range)

      assert %{status: "progress"} =
               Progression.evaluate("dynamic_double_progression", %{reps: 15, weight: 60.0}, @range)
    end

    test "holds inside the range" do
      assert %{status: "hold", target_weight: 60.0} =
               Progression.evaluate("dynamic_double_progression", %{reps: 10.0, weight: 60.0}, @range)

      assert %{status: "hold"} =
               Progression.evaluate("dynamic_double_progression", %{reps: 8, weight: 60.0}, @range)
    end

    test "reduces below the bottom of the range" do
      assert %{status: "reduce", target_weight: 60.0} =
               Progression.evaluate("dynamic_double_progression", %{reps: 6.0, weight: 60.0}, @range)
    end

    test "ignores sets that cannot be judged" do
      assert :ignored = Progression.evaluate("dynamic_double_progression", %{reps: nil, weight: 60.0}, @range)
      assert :ignored = Progression.evaluate("dynamic_double_progression", %{reps: 10, weight: nil}, @range)
      assert :ignored = Progression.evaluate("dynamic_double_progression", %{reps: 10, weight: 60.0}, %{min_reps: nil, max_reps: 12})
    end
  end

  test "the none method is ignored" do
    assert :ignored = Progression.evaluate("none", %{reps: 12, weight: 60.0}, @range)
  end

  test "all/0 lists the available methods" do
    assert {"None", "none"} in Progression.all()
    assert {"Dynamic Double Progression", "dynamic_double_progression"} in Progression.all()
  end
end
