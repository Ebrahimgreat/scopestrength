defmodule Crohnjobs.AI.WorkoutBot do
  @moduledoc """
  Rule-based workout tracking bot that handles workout logging without AI.
  Falls back to AI for general fitness questions.
  """

  alias Crohnjobs.Repo
  alias Crohnjobs.Clients
  alias Crohnjobs.Training
  alias Crohnjobs.Exercises.Exercise

  @doc """
  Process user message and return response.
  Returns {:bot, response} for rule-based responses
  Returns {:ai, prompt} to delegate to AI
  """
  def process_message(message, user, conversation_state \\ %{}) do
    message_lower = String.downcase(String.trim(message))

    cond do
      # Workout tracking intent
      workout_tracking_intent?(message_lower) ->
        handle_workout_tracking(message, user, conversation_state)

      # Stats query
      stats_intent?(message_lower) ->
        handle_stats_query(user)

      # List exercises
      list_exercises_intent?(message_lower) ->
        handle_list_exercises()

      # Default to AI for general questions
      true ->
        {:ai, message}
    end
  end

  defp workout_tracking_intent?(message) do
    keywords = ["track", "log", "record", "add workout", "create workout"]
    Enum.any?(keywords, &String.contains?(message, &1))
  end

  defp stats_intent?(message) do
    keywords = ["how many workout", "my stats", "my progress", "workout count", "show my volume"]
    Enum.any?(keywords, &String.contains?(message, &1))
  end

  defp list_exercises_intent?(message) do
    keywords = ["list exercises", "show exercises", "what exercises", "available exercises"]
    Enum.any?(keywords, &String.contains?(message, &1))
  end

  defp handle_workout_tracking(message, user, state) do
    case state do
      %{step: :awaiting_name} ->
        # Step 2: Got workout name, ask for date
        {:bot, "Great! What date did you do this workout? (say 'today', 'yesterday', or a date)",
         %{step: :awaiting_date, workout_name: message}}

      %{step: :awaiting_date, workout_name: name} ->
        # Step 3: Got date, ask for exercises
        {:bot,
         """
         Perfect! Now tell me the exercises you did.

         Format each exercise like this:
         Exercise Name - SetsxReps@Weight

         Examples:
         - Bench Press - 3x8@80
         - Squat - 4x5@100
         - Pull Up - 3x10@bodyweight

         You can list multiple exercises, one per line or separated by commas.
         """,
         %{step: :awaiting_exercises, workout_name: name, workout_date: message}}

      %{step: :awaiting_exercises, workout_name: name, workout_date: date} ->
        # Step 4: Got exercises, create the workout
        create_workout_from_input(name, date, message, user)

      _ ->
        # Step 1: Initial tracking request
        {:bot, "Let's track your workout! What would you like to name it? (e.g., 'Push Day', 'Leg Day', 'Upper Body')",
         %{step: :awaiting_name}}
    end
  end

  defp create_workout_from_input(name, date_str, exercises_str, user) do
    if user.role != "client" do
      {:bot, "❌ Only clients can track workouts.", %{}}
    else
      client = Repo.get_by(Clients.Client, user_id: user.id)

      if !client do
        {:bot, "❌ Client not found.", %{}}
      else
        workout_date = parse_date(date_str)

        case Training.create_workout(%{
               client_id: client.id,
               name: name,
               date: workout_date
             }) do
          {:ok, workout} ->
            # Parse exercises
            exercises = parse_exercises(exercises_str)
            results = create_workout_exercises(workout.id, exercises)

            successful = Enum.count(results, fn {status, _} -> status == :ok end)
            failed = Enum.count(results, fn {status, _} -> status == :error end)

            response =
              if failed > 0 do
                """
                ✅ Workout '#{name}' created with #{successful} exercises!

                ⚠️ #{failed} exercises couldn't be added (check exercise names).

                You can view and edit your workout in the workouts page.
                """
              else
                """
                ✅ Workout '#{name}' created successfully with #{successful} exercises!

                You can view it in your workouts page.
                """
              end

            {:bot, response, %{}}

          {:error, _changeset} ->
            {:bot, "❌ Error creating workout. Please try again.", %{}}
        end
      end
    end
  end

  defp parse_exercises(input) do
    input
    |> String.split(["\n", ","])
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&parse_single_exercise/1)
    |> Enum.reject(&is_nil/1)
  end

  defp parse_single_exercise(line) do
    # Pattern: "Exercise Name - 3x8@80" or "Exercise Name - 3x8 @ 80kg"
    case Regex.run(~r/^(.+?)\s*-\s*(\d+)\s*x\s*(\d+)\s*@?\s*(.+)$/i, line) do
      [_, name, sets, reps, weight] ->
        weight_clean = weight |> String.downcase() |> String.replace(~r/[^\d.]/, "")

        %{
          name: String.trim(name),
          sets: String.to_integer(sets),
          reps: String.to_integer(reps),
          weight:
            case Float.parse(weight_clean) do
              {w, _} -> w
              :error -> if String.contains?(String.downcase(weight), "bodyweight"), do: 0, else: 0
            end
        }

      _ ->
        nil
    end
  end

  defp create_workout_exercises(workout_id, exercises) do
    Enum.map(exercises, fn ex ->
      # Find exercise by name (case insensitive)
      exercise =
        Repo.all(Exercise)
        |> Enum.find(fn e ->
          String.downcase(e.name) == String.downcase(ex.name)
        end)

      if exercise do
        # Create sets
        results =
          for set_num <- 1..ex.sets do
            Training.create_workout_details(%{
              workout_id: workout_id,
              exercise_id: exercise.id,
              set: set_num,
              reps: ex.reps * 1.0,
              weight: ex.weight * 1.0
            })
          end

        if Enum.all?(results, fn {status, _} -> status == :ok end) do
          {:ok, exercise.name}
        else
          {:error, "Failed to create sets for #{ex.name}"}
        end
      else
        {:error, "Exercise '#{ex.name}' not found"}
      end
    end)
  end

  defp handle_stats_query(user) do
    if user.role != "client" do
      {:bot, "Stats are only available for clients.", %{}}
    else
      client = Repo.get_by(Clients.Client, user_id: user.id)

      if !client do
        {:bot, "❌ Client not found.", %{}}
      else
        stats = get_client_stats(client.id)

        volume_text =
          if map_size(stats.muscle_volume_7d) > 0 do
            muscle_breakdown =
              stats.muscle_volume_7d
              |> Enum.map(fn {muscle, volumes} ->
                "  • #{muscle}: #{round(volumes.direct)} direct sets, #{round(volumes.effective)} effective sets"
              end)
              |> Enum.join("\n")

            "\n\n📊 Muscle Volume (Last 7 Days):\n#{muscle_breakdown}"
          else
            ""
          end

        response = """
        📈 Your Workout Stats:

        • Total workouts: #{stats.total_workouts}
        • Workouts in last 7 days: #{stats.recent_workouts}
        • Total sets logged: #{stats.total_sets}#{volume_text}

        Keep up the great work! 💪
        """

        {:bot, response, %{}}
      end
    end
  end

  defp handle_list_exercises do
    exercises =
      Repo.all(Exercise)
      |> Enum.take(20)
      |> Enum.map(& &1.name)
      |> Enum.join(", ")

    response = """
    Here are some common exercises in our database:

    #{exercises}

    (and many more...)

    Use these exact names when tracking workouts!
    """

    {:bot, response, %{}}
  end

  defp parse_date(date_str) do
    date_str = String.trim(String.downcase(date_str))

    case date_str do
      "today" -> DateTime.utc_now()
      "yesterday" -> DateTime.utc_now() |> DateTime.add(-1, :day)
      _ -> DateTime.utc_now()
    end
  end

  defp get_client_stats(client_id) do
    import Ecto.Query
    alias Crohnjobs.Training.Workout
    alias Crohnjobs.Training.WorkoutDetails
    alias Crohnjobs.Exercises.ExerciseMuscleContribution

    total_workouts =
      Repo.aggregate(
        from(w in Workout, where: w.client_id == ^client_id),
        :count,
        :id
      )

    seven_days_ago = DateTime.utc_now() |> DateTime.add(-7, :day)

    recent_workouts =
      Repo.aggregate(
        from(w in Workout,
          where: w.client_id == ^client_id and w.inserted_at >= ^seven_days_ago
        ),
        :count,
        :id
      )

    total_sets =
      Repo.aggregate(
        from(wd in WorkoutDetails,
          join: w in Workout,
          on: wd.workout_id == w.id,
          where: w.client_id == ^client_id
        ),
        :count,
        :id
      )

    recent_workout_details =
      Repo.all(
        from(wd in WorkoutDetails,
          join: w in Workout,
          on: wd.workout_id == w.id,
          where: w.client_id == ^client_id and w.inserted_at >= ^seven_days_ago,
          select: wd
        )
      )

    muscle_volume_7d = calculate_muscle_volume(recent_workout_details)

    %{
      total_workouts: total_workouts,
      recent_workouts: recent_workouts,
      total_sets: total_sets,
      muscle_volume_7d: muscle_volume_7d
    }
  end

  defp calculate_muscle_volume(workout_details) do
    import Ecto.Query
    alias Crohnjobs.Exercises.ExerciseMuscleContribution

    exercise_ids =
      workout_details
      |> Enum.map(& &1.exercise_id)
      |> Enum.uniq()

    if Enum.empty?(exercise_ids) do
      %{}
    else
      muscle_contributions =
        Repo.all(
          from c in ExerciseMuscleContribution,
            where: c.exercise_id in ^exercise_ids
        )
        |> Repo.preload(:muscle)

      contributions_by_exercise =
        muscle_contributions
        |> Enum.group_by(& &1.exercise_id)

      workout_details
      |> Enum.flat_map(fn detail ->
        contributions = Map.get(contributions_by_exercise, detail.exercise_id, [])

        Enum.map(contributions, fn c ->
          {c.muscle.name, c.role, 1 * c.multiplier}
        end)
      end)
      |> Enum.group_by(fn {muscle, _role, _volume} -> muscle end)
      |> Enum.map(fn {muscle, rows} ->
        direct_sets =
          rows
          |> Enum.filter(fn {_m, role, _v} -> role == "primary" end)
          |> Enum.map(fn {_m, _r, v} -> v end)
          |> Enum.sum()

        effective_sets =
          rows
          |> Enum.map(fn {_m, _r, v} -> v end)
          |> Enum.sum()

        {muscle, %{direct: direct_sets, effective: effective_sets}}
      end)
      |> Map.new()
    end
  end
end
