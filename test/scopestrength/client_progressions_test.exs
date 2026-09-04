defmodule Scopestrength.ClientProgressionsTest do
  use Scopestrength.DataCase, async: true

  import Scopestrength.ExercisesFixtures
  import Scopestrength.PeopleFixtures
  import Scopestrength.ProgrammesFixtures
  import Scopestrength.TrainingFixtures

  alias Scopestrength.{ClientProgressions, Programmes, Training}
  alias Scopestrength.ClientProgressions.ClientProgression

  defp rows(client_id, exercise_id) do
    client_id
    |> ClientProgressions.list_for_exercise(exercise_id)
    |> Enum.map(&{&1.set_number, &1.side, &1.min_reps, &1.max_reps, &1.status})
  end

  describe "seed_from_programme/2" do
    test "creates one row per set for bilateral exercises" do
      client = client_fixture()
      %{programme: programme, exercise: exercise} = full_programme_fixture()

      {:ok, 2} = ClientProgressions.seed_from_programme(client.id, Programmes.get_programme_with_template(programme.id))
      assert rows(client.id, exercise.id) == [{1, "both", 8, 12, "hold"}, {2, "both", 8, 12, "hold"}]
    end

    test "creates left and right rows for unilateral exercises" do
      client = client_fixture()
      exercise = unilateral_exercise_fixture()
      %{programme: programme} = full_programme_fixture(%{exercise: exercise})

      {:ok, 4} = ClientProgressions.seed_from_programme(client.id, Programmes.get_programme_with_template(programme.id))

      assert rows(client.id, exercise.id) == [
               {1, "left", 8, 12, "hold"},
               {1, "right", 8, 12, "hold"},
               {2, "left", 8, 12, "hold"},
               {2, "right", 8, 12, "hold"}
             ]
    end

    test "skips exercises without a rep range and keeps status on re-seed" do
      client = client_fixture()
      %{programme: programme, details: details, exercise: exercise} = full_programme_fixture()
      no_range = programme_details_fixture(%{programme_template_id: details.programme_template_id, min_reps: nil, max_reps: nil})

      loaded = Programmes.get_programme_with_template(programme.id)
      {:ok, 2} = ClientProgressions.seed_from_programme(client.id, loaded)
      assert ClientProgressions.list_for_exercise(client.id, no_range.exercise_id) == []

      row = ClientProgressions.get_progression(client.id, exercise.id, 1)
      {:ok, _} = ClientProgressions.update_client_progression(row, %{status: "progress"})

      {:ok, _} = Programmes.update_programme_details(details, %{min_reps: 5, max_reps: 8})
      {:ok, 2} = ClientProgressions.seed_from_programme(client.id, Programmes.get_programme_with_template(programme.id))

      assert {1, "both", 5, 8, "progress"} in rows(client.id, exercise.id)
    end
  end

  describe "process_workout_detail/2" do
    setup do
      client = client_fixture()
      exercise = exercise_fixture()
      workout = workout_fixture(%{client_id: client.id})
      %{client: client, exercise: exercise, workout: workout}
    end

    test "judges the set, updates the row and stamps the set", ctx do
      {:ok, _} =
        ClientProgressions.create_client_progression(%{
          client_id: ctx.client.id,
          exercise_id: ctx.exercise.id,
          set_number: 1,
          progression_method: "dynamic_double_progression",
          min_reps: 8,
          max_reps: 12
        })

      detail = workout_details_fixture(%{workout_id: ctx.workout.id, exercise_id: ctx.exercise.id, set: 1, reps: 12.0, weight: 70.0})

      assert {:ok, "progress"} = ClientProgressions.process_workout_detail(ctx.client.id, detail)

      row = ClientProgressions.get_progression(ctx.client.id, ctx.exercise.id, 1)
      assert row.status == "progress"
      assert row.target_weight == 70.0
      assert Training.get_workout_details!(detail.id).progression_status == "progress"
    end

    test "extra sets inherit the prescription of existing sets", ctx do
      for set <- 1..2 do
        {:ok, _} =
          ClientProgressions.create_client_progression(%{
            client_id: ctx.client.id,
            exercise_id: ctx.exercise.id,
            set_number: set,
            progression_method: "dynamic_double_progression",
            min_reps: 8,
            max_reps: 12
          })
      end

      detail = workout_details_fixture(%{workout_id: ctx.workout.id, exercise_id: ctx.exercise.id, set: 3, reps: 6.0, weight: 70.0})
      assert {:ok, "reduce"} = ClientProgressions.process_workout_detail(ctx.client.id, detail)
      assert {3, "both", 8, 12, "reduce"} in rows(ctx.client.id, ctx.exercise.id)
    end

    test "an exercise with no rows gets the default range", ctx do
      detail = workout_details_fixture(%{workout_id: ctx.workout.id, exercise_id: ctx.exercise.id, set: 1, reps: 10.0, weight: 20.0})
      assert {:ok, "progress"} = ClientProgressions.process_workout_detail(ctx.client.id, detail)
      assert rows(ctx.client.id, ctx.exercise.id) == [{1, "both", 5, 10, "progress"}]
    end

    test "a programme on the none method is ignored", ctx do
      {:ok, _} =
        ClientProgressions.create_client_progression(%{
          client_id: ctx.client.id,
          exercise_id: ctx.exercise.id,
          set_number: 1,
          progression_method: "none",
          min_reps: 8,
          max_reps: 12
        })

      detail = workout_details_fixture(%{workout_id: ctx.workout.id, exercise_id: ctx.exercise.id, set: 1, reps: 12.0, weight: 70.0})
      assert :ignored = ClientProgressions.process_workout_detail(ctx.client.id, detail)
      assert Training.get_workout_details!(detail.id).progression_status == "hold"
    end
  end

  describe "unilateral exercises" do
    test "left and right sides progress independently" do
      client = client_fixture()
      exercise = unilateral_exercise_fixture()
      workout = workout_fixture(%{client_id: client.id})

      for side <- ["left", "right"] do
        {:ok, _} =
          ClientProgressions.create_client_progression(%{
            client_id: client.id,
            exercise_id: exercise.id,
            set_number: 1,
            side: side,
            progression_method: "dynamic_double_progression",
            min_reps: 8,
            max_reps: 12
          })
      end

      left = workout_details_fixture(%{workout_id: workout.id, exercise_id: exercise.id, set: 1, side: "left", reps: 10.0, weight: 20.0})
      right = workout_details_fixture(%{workout_id: workout.id, exercise_id: exercise.id, set: 1, side: "right", reps: 12.0, weight: 20.0})
      extra = workout_details_fixture(%{workout_id: workout.id, exercise_id: exercise.id, set: 2, side: "left", reps: 6.0, weight: 20.0})

      assert {:ok, "hold"} = ClientProgressions.process_workout_detail(client.id, left)
      assert {:ok, "progress"} = ClientProgressions.process_workout_detail(client.id, right)
      assert {:ok, "reduce"} = ClientProgressions.process_workout_detail(client.id, extra)

      assert rows(client.id, exercise.id) == [
               {1, "left", 8, 12, "hold"},
               {1, "right", 8, 12, "progress"},
               {2, "left", 8, 12, "reduce"}
             ]

      {:ok, 3} = ClientProgressions.update_exercise_progression(client.id, exercise.id, %{"min_reps" => "11", "max_reps" => "12"})

      assert rows(client.id, exercise.id) == [
               {1, "left", 11, 12, "reduce"},
               {1, "right", 11, 12, "progress"},
               {2, "left", 11, 12, "reduce"}
             ]
    end
  end

  describe "update_exercise_progression/3" do
    test "rejects a max below the min" do
      client = client_fixture()
      exercise = exercise_fixture()

      {:ok, _} =
        ClientProgressions.create_client_progression(%{client_id: client.id, exercise_id: exercise.id, set_number: 1, min_reps: 8, max_reps: 12})

      assert {:error, %Ecto.Changeset{} = changeset} =
               ClientProgressions.update_exercise_progression(client.id, exercise.id, %{"min_reps" => "12", "max_reps" => "8"})

      assert "must be greater than or equal to min_reps" in errors_on(changeset).max_reps
    end
  end

  test "duplicate rows for the same client, exercise, set and side are rejected" do
    client = client_fixture()
    exercise = exercise_fixture()
    attrs = %{client_id: client.id, exercise_id: exercise.id, set_number: 1, side: "both"}

    {:ok, _} = ClientProgressions.create_client_progression(attrs)
    {:error, changeset} = ClientProgressions.create_client_progression(attrs)
    assert errors_on(changeset) != %{}
    assert [%ClientProgression{}] = ClientProgressions.list_for_exercise(client.id, exercise.id)
  end
end
