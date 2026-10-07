# ScopeStrength - personal trainer management application
# Copyright (C) 2026  Ebrahim Shahid Arshad
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# SPDX-License-Identifier: AGPL-3.0-or-later

defmodule ScopestrengthWeb.Mcp.Tools do
  @moduledoc """
  The tools ScopeStrength exposes over MCP.

  Every tool receives a context with the authenticated `:user`, `:client` and
  `:token` (nil for the static config token). Reads and writes are always
  scoped to that client; no tool accepts a client id. Tools that change data
  also require a token with write scope.

  Output is shaped for an assistant reading it on a phone: names alongside
  ids, nil fields dropped, whole-number floats shown as integers.
  """

  import Ecto.Query, warn: false

  alias Scopestrength.ApiTokens
  alias Scopestrength.ClientProgressions
  alias Scopestrength.ClientProgressions.ClientProgression
  alias Scopestrength.Exercises.Exercise, as: ExerciseRow
  alias Scopestrength.Programmes.Programme
  alias Scopestrength.Programmes.ProgrammeDetails
  alias Scopestrength.Programmes.ProgrammeTemplate
  alias Scopestrength.Programmes.ProgrammeUser
  alias Scopestrength.Repo
  alias Scopestrength.Training
  alias Scopestrength.Training.Workout
  alias Scopestrength.Training.WorkoutDetails

  @max_sets_per_call 100

  # --- definitions -----------------------------------------------------------

  def instructions do
    """
    ScopeStrength is the user's strength training log. All data belongs to the \
    signed-in client.

    Today's workout: call recent_workouts (limit 5) and get_programme. Workouts \
    are named after the programme day they followed, so the next day is the one \
    after the most recently logged day (wrap around at the end). Show each \
    exercise as sets x rep range with the target weight.

    Reading targets: each exercise's targets carry the last working weight and a \
    status. "progress" means the top of the rep range was hit, so suggest a \
    small weight increase; "hold" means keep the weight and add reps; "reduce" \
    means drop the weight. last_time shows what was actually done.

    Logging: use log_workout once per session, named after the programme day, \
    with every set. To add sets to a session already logged today use add_sets \
    with its workout_id. Use exercise_id from get_programme or search_exercises \
    when known; an exact exercise name also works. Weights are in whatever unit \
    the user already logs in (see recent_workouts). Confirm what was logged.
    """
  end

  def definitions do
    [
      %{
        name: "get_programme",
        title: "Get programme",
        description:
          "The user's training programme: every day with its exercises, sets, rep range, " <>
            "target weights with progression status, and what was lifted last time. " <>
            "Defaults to the active programme. Pass day to get just one day.",
        inputSchema: %{
          type: "object",
          properties: %{
            programme_id: %{
              type: "integer",
              description: "Optional. Defaults to the active programme."
            },
            day: %{
              type: "string",
              description: "Optional day name filter, e.g. \"Push\" or \"Day 2\"."
            }
          }
        },
        annotations: %{readOnlyHint: true}
      },
      %{
        name: "list_programmes",
        title: "List programmes",
        description:
          "Programmes available to the user (assigned by their trainer or their own), " <>
            "with their day names. Use get_programme for the exercises.",
        inputSchema: %{type: "object", properties: %{}},
        annotations: %{readOnlyHint: true}
      },
      %{
        name: "recent_workouts",
        title: "Recent workouts",
        description: "The user's most recent logged workouts, newest first, with every set.",
        inputSchema: %{
          type: "object",
          properties: %{
            limit: %{type: "integer", description: "How many workouts, 1 to 20. Default 5."}
          }
        },
        annotations: %{readOnlyHint: true}
      },
      %{
        name: "exercise_history",
        title: "Exercise history",
        description:
          "One exercise's progression targets and its last few sessions. " <>
            "Pass exercise_id, or exercise as an exact name.",
        inputSchema: %{
          type: "object",
          properties: %{
            exercise_id: %{type: "integer"},
            exercise: %{type: "string", description: "Exact exercise name."},
            sessions: %{type: "integer", description: "1 to 20. Default 5."}
          }
        },
        annotations: %{readOnlyHint: true}
      },
      %{
        name: "search_exercises",
        title: "Search exercises",
        description: "Find exercises in the library by part of their name, to get exercise_id.",
        inputSchema: %{
          type: "object",
          properties: %{
            query: %{type: "string", description: "Part of the name, e.g. \"bench\"."},
            limit: %{type: "integer", description: "1 to 50. Default 15."}
          },
          required: ["query"]
        },
        annotations: %{readOnlyHint: true}
      },
      %{
        name: "log_workout",
        title: "Log workout",
        description:
          "Log a completed session with its sets. Updates progression targets the same way " <>
            "saving sets in the app does. Name it after the programme day.",
        inputSchema: %{
          type: "object",
          properties: %{
            name: %{type: "string", description: "Programme day name, e.g. \"Push\"."},
            date: %{
              type: "string",
              description: "YYYY-MM-DD or ISO 8601 datetime. Defaults to now."
            },
            notes: %{type: "string"},
            sets: sets_schema()
          },
          required: ["name", "sets"]
        },
        annotations: %{readOnlyHint: false, destructiveHint: false}
      },
      %{
        name: "add_sets",
        title: "Add sets",
        description:
          "Append sets to a workout that is already logged, e.g. while still training. " <>
            "Set numbers continue from the sets already there.",
        inputSchema: %{
          type: "object",
          properties: %{
            workout_id: %{type: "integer"},
            sets: sets_schema()
          },
          required: ["workout_id", "sets"]
        },
        annotations: %{readOnlyHint: false, destructiveHint: false}
      },
      %{
        name: "delete_workout",
        title: "Delete workout",
        description: "Permanently delete one logged workout and its sets.",
        inputSchema: %{
          type: "object",
          properties: %{workout_id: %{type: "integer"}},
          required: ["workout_id"]
        },
        annotations: %{readOnlyHint: false, destructiveHint: true}
      }
    ]
  end

  defp sets_schema do
    %{
      type: "array",
      description: "One entry per set, in the order performed.",
      items: %{
        type: "object",
        properties: %{
          exercise_id: %{type: "integer"},
          exercise: %{type: "string", description: "Exact name, if exercise_id is unknown."},
          reps: %{type: "number"},
          weight: %{type: "number", description: "Omit for bodyweight."},
          rir: %{type: "number", description: "Reps in reserve."},
          rpe: %{type: "number", description: "1 to 10."},
          side: %{type: "string", enum: ["both", "left", "right"]},
          set: %{
            type: "integer",
            description: "Set number within the exercise. Usually omit; it is numbered for you."
          }
        }
      }
    }
  end

  # --- dispatch --------------------------------------------------------------

  def call("get_programme", args, ctx), do: get_programme(args, ctx)
  def call("list_programmes", _args, ctx), do: list_programmes(ctx)
  def call("recent_workouts", args, ctx), do: recent_workouts(args, ctx)
  def call("exercise_history", args, ctx), do: exercise_history(args, ctx)
  def call("search_exercises", args, _ctx), do: search_exercises(args)
  def call("log_workout", args, ctx), do: log_workout(args, ctx)
  def call("add_sets", args, ctx), do: add_sets(args, ctx)
  def call("delete_workout", args, ctx), do: delete_workout(args, ctx)
  def call(_name, _args, _ctx), do: :unknown_tool

  # --- programmes ------------------------------------------------------------

  defp list_programmes(ctx) do
    active_id = active_programme_id(ctx.client.id)

    programmes =
      from(p in Programme,
        where: p.user_id == ^ctx.user.id or p.id == ^(active_id || -1),
        order_by: [desc: p.updated_at]
      )
      |> Repo.all()
      |> Repo.preload(programmeTemplates: {templates_query(), programmeDetails: details_query()})

    {:ok,
     %{
       active_programme_id: active_id,
       programmes:
         Enum.map(programmes, fn p ->
           compact(%{
             programme_id: p.id,
             name: p.name,
             description: p.description,
             active: p.id == active_id,
             days:
               Enum.map(p.programmeTemplates, fn t ->
                 %{day_id: t.id, name: t.name, exercises: length(t.programmeDetails)}
               end)
           })
         end)
     }}
  end

  defp get_programme(args, ctx) do
    with {:ok, programme} <- resolve_programme(Map.get(args, "programme_id"), ctx),
         programme =
           Repo.preload(programme,
             programmeTemplates:
               {templates_query(), programmeDetails: {details_query(), :exercise}}
           ),
         {:ok, days} <- filter_days(programme.programmeTemplates, Map.get(args, "day")) do
      exercise_ids =
        days |> Enum.flat_map(& &1.programmeDetails) |> Enum.map(& &1.exercise_id) |> Enum.uniq()

      targets = targets_by_exercise(ctx.client.id, exercise_ids)
      last = last_session_by_exercise(ctx.client.id, exercise_ids)

      {:ok,
       compact(%{
         programme_id: programme.id,
         name: programme.name,
         description: programme.description,
         days:
           Enum.map(days, fn day ->
             %{
               day_id: day.id,
               name: day.name,
               exercises:
                 Enum.map(day.programmeDetails, fn d ->
                   compact(%{
                     exercise_id: d.exercise_id,
                     exercise: d.exercise && d.exercise.name,
                     sets: parse_int(d.set) || d.set,
                     reps: rep_range(d),
                     rir: d.rir,
                     targets: Map.get(targets, d.exercise_id),
                     last_time: Map.get(last, d.exercise_id)
                   })
                 end)
             }
           end)
       })}
    end
  end

  defp resolve_programme(nil, ctx) do
    case active_programme_id(ctx.client.id) do
      nil ->
        from(p in Programme,
          where: p.user_id == ^ctx.user.id,
          order_by: [desc: p.updated_at],
          limit: 1
        )
        |> Repo.one()
        |> case do
          nil -> {:error, "No programme found. The user has no active or own programme."}
          programme -> {:ok, programme}
        end

      id ->
        {:ok, Repo.get!(Programme, id)}
    end
  end

  defp resolve_programme(raw_id, ctx) do
    with {:ok, id} <- require_int(raw_id, "programme_id"),
         %Programme{} = programme <- Repo.get(Programme, id),
         true <- programme.user_id == ctx.user.id or assigned?(ctx.client.id, id) do
      {:ok, programme}
    else
      {:error, _} = error -> error
      _ -> {:error, "Programme not found. Use list_programmes for valid ids."}
    end
  end

  defp active_programme_id(client_id) do
    from(pu in ProgrammeUser,
      where: pu.client_id == ^client_id and pu.is_active == true,
      select: pu.programme_id,
      limit: 1
    )
    |> Repo.one()
  end

  # Same rule as Programmes.clone_assigned_programme: any assignment, past or
  # present, lets the client read that programme.
  defp assigned?(client_id, programme_id) do
    from(pu in ProgrammeUser,
      where: pu.client_id == ^client_id and pu.programme_id == ^programme_id
    )
    |> Repo.exists?()
  end

  defp filter_days(days, day) when is_binary(day) and day != "" do
    needle = String.downcase(String.trim(day))
    exact = Enum.filter(days, &(String.downcase(&1.name || "") == needle))

    matched =
      if exact != [],
        do: exact,
        else: Enum.filter(days, &String.contains?(String.downcase(&1.name || ""), needle))

    case matched do
      [] -> {:error, "No day matching \"#{day}\". Days: #{Enum.map_join(days, ", ", & &1.name)}"}
      found -> {:ok, found}
    end
  end

  defp filter_days(days, _day), do: {:ok, days}

  defp templates_query, do: from(t in ProgrammeTemplate, order_by: t.id)
  defp details_query, do: from(d in ProgrammeDetails, order_by: d.id)

  defp rep_range(%{min_reps: min, max_reps: max}) when is_integer(min) and is_integer(max),
    do: "#{min}-#{max}"

  defp rep_range(%{reps: reps}) when is_binary(reps) and reps != "", do: reps
  defp rep_range(_), do: nil

  defp targets_by_exercise(_client_id, []), do: %{}

  defp targets_by_exercise(client_id, exercise_ids) do
    from(cp in ClientProgression,
      where: cp.client_id == ^client_id and cp.exercise_id in ^exercise_ids,
      order_by: [asc: cp.set_number, asc: cp.side]
    )
    |> Repo.all()
    |> Enum.group_by(& &1.exercise_id, &format_target/1)
  end

  defp format_target(row) do
    compact(%{
      set: row.set_number,
      side: side(row.side),
      target_weight: num(row.target_weight),
      reps: if(row.min_reps && row.max_reps, do: "#{row.min_reps}-#{row.max_reps}"),
      status: row.status
    })
  end

  # The most recent workout containing each exercise, and that exercise's
  # sets in it. DISTINCT ON keeps this to two queries however long the
  # history is.
  defp last_session_by_exercise(_client_id, []), do: %{}

  defp last_session_by_exercise(client_id, exercise_ids) do
    latest =
      from(wd in WorkoutDetails,
        join: w in Workout,
        on: wd.workout_id == w.id,
        where: w.client_id == ^client_id and wd.exercise_id in ^exercise_ids,
        distinct: wd.exercise_id,
        order_by: [desc: coalesce(w.date, w.inserted_at), desc: w.id],
        select: {wd.exercise_id, w.id, coalesce(w.date, w.inserted_at)}
      )
      |> Repo.all()

    pairs = MapSet.new(latest, fn {exercise_id, workout_id, _} -> {exercise_id, workout_id} end)
    workout_ids = Enum.map(latest, &elem(&1, 1))

    sets =
      from(wd in WorkoutDetails,
        where: wd.workout_id in ^workout_ids and wd.exercise_id in ^exercise_ids,
        order_by: [asc: wd.set, asc: wd.side, asc: wd.id]
      )
      |> Repo.all()
      |> Enum.filter(&MapSet.member?(pairs, {&1.exercise_id, &1.workout_id}))
      |> Enum.group_by(& &1.exercise_id)

    Map.new(latest, fn {exercise_id, _workout_id, date} ->
      {exercise_id,
       %{date: format_date(date), sets: Enum.map(Map.get(sets, exercise_id, []), &format_set/1)}}
    end)
  end

  # --- workouts --------------------------------------------------------------

  defp recent_workouts(args, ctx) do
    limit = clamp(Map.get(args, "limit"), 1, 20, 5)

    workouts =
      ctx.client.id
      |> Training.list_workouts_for_client(limit: limit)
      |> Enum.map(&format_workout/1)

    {:ok, %{workouts: workouts}}
  end

  defp exercise_history(args, ctx) do
    with {:ok, exercise} <- resolve_exercise(args) do
      sessions = clamp(Map.get(args, "sessions"), 1, 20, 5)

      workouts =
        from(w in Workout,
          where:
            w.client_id == ^ctx.client.id and
              w.id in subquery(
                from wd in WorkoutDetails,
                  where: wd.exercise_id == ^exercise.id,
                  select: wd.workout_id
              ),
          order_by: [desc: coalesce(w.date, w.inserted_at), desc: w.id],
          limit: ^sessions
        )
        |> Repo.all()

      workout_ids = Enum.map(workouts, & &1.id)

      sets =
        from(wd in WorkoutDetails,
          where: wd.workout_id in ^workout_ids and wd.exercise_id == ^exercise.id,
          order_by: [asc: wd.set, asc: wd.side, asc: wd.id]
        )
        |> Repo.all()
        |> Enum.group_by(& &1.workout_id)

      {:ok,
       compact(%{
         exercise_id: exercise.id,
         exercise: exercise.name,
         targets: Map.get(targets_by_exercise(ctx.client.id, [exercise.id]), exercise.id),
         sessions:
           Enum.map(workouts, fn w ->
             compact(%{
               workout_id: w.id,
               name: w.name,
               date: format_date(w.date || w.inserted_at),
               sets: Enum.map(Map.get(sets, w.id, []), &format_set/1)
             })
           end)
       })}
    end
  end

  defp search_exercises(args) do
    query = Map.get(args, "query")

    if is_binary(query) and String.trim(query) != "" do
      limit = clamp(Map.get(args, "limit"), 1, 50, 15)

      exercises =
        query
        |> Scopestrength.Exercise.search_exercises_by_name(limit: limit)
        |> Enum.map(&%{exercise_id: &1.id, name: &1.name, unilateral: &1.is_unilateral})

      {:ok, %{exercises: exercises}}
    else
      {:error, "query is required"}
    end
  end

  defp log_workout(args, ctx) do
    name = Map.get(args, "name")

    with :ok <- require_write(ctx),
         :ok <- require_string(name, "name"),
         {:ok, date} <- parse_date(Map.get(args, "date")),
         {:ok, sets} <- build_sets(Map.get(args, "sets"), %{}),
         {:ok, workout} <-
           Training.create_workout_with_sets(
             %{client_id: ctx.client.id, name: name, notes: Map.get(args, "notes"), date: date},
             sets
           )
           |> changeset_error() do
      run_progression(ctx.client.id, workout.workoutDetails)
      {:ok, %{logged: format_workout(Training.get_workout_with_sets(workout.id))}}
    end
  end

  defp add_sets(args, ctx) do
    with :ok <- require_write(ctx),
         {:ok, workout_id} <- require_int(Map.get(args, "workout_id"), "workout_id"),
         {:ok, _} <- fetch_workout(ctx, workout_id),
         workout = Training.get_workout_with_sets(workout_id),
         {:ok, sets} <- build_sets(Map.get(args, "sets"), set_counts(workout.workoutDetails)),
         {:ok, inserted} <- insert_sets(workout_id, sets) do
      run_progression(ctx.client.id, inserted)
      {:ok, %{workout: format_workout(Training.get_workout_with_sets(workout_id))}}
    end
  end

  defp delete_workout(args, ctx) do
    with :ok <- require_write(ctx),
         {:ok, workout_id} <- require_int(Map.get(args, "workout_id"), "workout_id"),
         {:ok, workout} <- fetch_workout(ctx, workout_id),
         {:ok, _} <- Training.delete_workout(workout) |> changeset_error() do
      {:ok, %{deleted_workout_id: workout_id, name: workout.name}}
    end
  end

  defp fetch_workout(ctx, workout_id) do
    case Training.fetch_client_workout(ctx.client.id, workout_id) do
      {:ok, workout} -> {:ok, workout}
      {:error, :not_found} -> {:error, "Workout #{workout_id} not found."}
    end
  end

  defp insert_sets(workout_id, sets) do
    Repo.transaction(fn ->
      Enum.map(sets, fn attrs ->
        case Training.create_workout_details(Map.put(attrs, :workout_id, workout_id)) do
          {:ok, detail} -> detail
          {:error, changeset} -> Repo.rollback(changeset)
        end
      end)
    end)
    |> changeset_error()
  end

  # Mirrors the workout page, which runs every saved set through the
  # client's progression so targets move with what was actually lifted.
  # A progression failure must not undo a logged set, so it is only logged.
  defp run_progression(client_id, details) do
    Enum.each(details, fn detail ->
      if is_number(detail.reps) and is_number(detail.weight) do
        try do
          ClientProgressions.process_workout_detail(client_id, detail)
        rescue
          exception ->
            require Logger
            Logger.warning("MCP progression update failed: #{Exception.message(exception)}")
        end
      end
    end)
  end

  # --- set parsing -----------------------------------------------------------

  # Sets come from an assistant, so each field is checked rather than trusted.
  # Set numbers are per exercise and side, which is how progression rows are
  # keyed; `counts` holds the highest number already used in the workout.
  defp build_sets(sets, counts) when is_list(sets) and sets != [] do
    if length(sets) > @max_sets_per_call do
      {:error, "Too many sets in one call (max #{@max_sets_per_call})."}
    else
      sets
      |> Enum.with_index(1)
      |> Enum.reduce_while({:ok, [], counts, %{}}, fn {set, index}, {:ok, acc, counts, cache} ->
        case build_set(set, index, counts, cache) do
          {:ok, attrs, counts, cache} -> {:cont, {:ok, [attrs | acc], counts, cache}}
          {:error, message} -> {:halt, {:error, message}}
        end
      end)
      |> case do
        {:ok, acc, _counts, _cache} -> {:ok, Enum.reverse(acc)}
        error -> error
      end
    end
  end

  defp build_sets(_sets, _counts), do: {:error, "sets must be a non-empty list"}

  defp build_set(set, index, counts, cache) when is_map(set) do
    side = Map.get(set, "side") || "both"

    with {:ok, exercise, cache} <- cached_exercise(set, cache, index),
         :ok <- check_side(side, index),
         {:ok, reps} <- optional_number(set, "reps", index),
         {:ok, weight} <- optional_number(set, "weight", index),
         {:ok, rir} <- optional_number(set, "rir", index),
         {:ok, rpe} <- optional_number(set, "rpe", index),
         {:ok, explicit} <- optional_set_number(set, index) do
      key = {exercise.id, side}
      number = explicit || Map.get(counts, key, 0) + 1

      attrs =
        %{exercise_id: exercise.id, set: number, side: side, reps: reps, weight: weight, rpe: rpe}
        |> then(fn attrs -> if rir, do: Map.put(attrs, :rir, rir), else: attrs end)

      {:ok, attrs, Map.update(counts, key, number, &max(&1, number)), cache}
    end
  end

  defp build_set(_set, index, _counts, _cache), do: {:error, "Set #{index} must be an object."}

  defp cached_exercise(set, cache, index) do
    key = {Map.get(set, "exercise_id"), Map.get(set, "exercise")}

    case Map.fetch(cache, key) do
      {:ok, exercise} ->
        {:ok, exercise, cache}

      :error ->
        case resolve_exercise(set) do
          {:ok, exercise} -> {:ok, exercise, Map.put(cache, key, exercise)}
          {:error, message} -> {:error, "Set #{index}: #{message}"}
        end
    end
  end

  defp check_side(side, _index) when side in ["both", "left", "right"], do: :ok
  defp check_side(_side, index), do: {:error, "Set #{index}: side must be both, left or right."}

  defp optional_number(map, key, index) do
    case Map.get(map, key) do
      nil ->
        {:ok, nil}

      value when is_number(value) ->
        {:ok, value * 1.0}

      value when is_binary(value) ->
        case Float.parse(value) do
          {n, ""} -> {:ok, n}
          _ -> {:error, "Set #{index}: #{key} must be a number."}
        end

      _ ->
        {:error, "Set #{index}: #{key} must be a number."}
    end
  end

  defp optional_set_number(map, index) do
    case Map.get(map, "set") do
      nil ->
        {:ok, nil}

      value ->
        case parse_int(value) do
          n when is_integer(n) and n > 0 -> {:ok, n}
          _ -> {:error, "Set #{index}: set must be a positive integer."}
        end
    end
  end

  defp set_counts(details) do
    Enum.reduce(details, %{}, fn d, acc ->
      Map.update(acc, {d.exercise_id, d.side || "both"}, d.set || 0, &max(&1, d.set || 0))
    end)
  end

  # By id, or by exact (case-insensitive) name. A near miss lists candidates
  # rather than guessing, so a typo cannot log sets against the wrong lift.
  defp resolve_exercise(%{"exercise_id" => raw} = args) when not is_nil(raw) do
    with {:ok, id} <- require_int(raw, "exercise_id") do
      case Repo.get(ExerciseRow, id) do
        nil -> resolve_by_name(args, "No exercise with id #{id}.")
        exercise -> {:ok, exercise}
      end
    end
  end

  defp resolve_exercise(args), do: resolve_by_name(args, nil)

  defp resolve_by_name(%{"exercise" => name}, _fallback) when is_binary(name) and name != "" do
    trimmed = String.trim(name)

    from(e in ExerciseRow,
      where: fragment("lower(?)", e.name) == ^String.downcase(trimmed),
      limit: 1
    )
    |> Repo.one()
    |> case do
      nil ->
        candidates =
          trimmed
          |> Scopestrength.Exercise.search_exercises_by_name(limit: 5)
          |> Enum.map_join(", ", &"#{&1.name} (#{&1.id})")

        {:error,
         "No exercise named \"#{trimmed}\"." <>
           if(candidates == "",
             do: " Try search_exercises.",
             else: " Did you mean: #{candidates}?"
           )}

      exercise ->
        {:ok, exercise}
    end
  end

  defp resolve_by_name(_args, nil), do: {:error, "Give exercise_id or exercise (name)."}
  defp resolve_by_name(_args, message), do: {:error, message}

  # --- formatting ------------------------------------------------------------

  defp format_workout(workout) do
    details = Enum.sort_by(workout.workoutDetails, & &1.id)
    order = details |> Enum.map(& &1.exercise_id) |> Enum.uniq()
    grouped = Enum.group_by(details, & &1.exercise_id)

    compact(%{
      workout_id: workout.id,
      name: workout.name,
      date: format_date(workout.date || workout.inserted_at),
      notes: workout.notes,
      exercises:
        Enum.map(order, fn exercise_id ->
          sets = grouped |> Map.get(exercise_id) |> Enum.sort_by(&{&1.set, &1.side})
          first = hd(sets)

          %{
            exercise_id: exercise_id,
            exercise: first.exercise && first.exercise.name,
            sets: Enum.map(sets, &format_set/1)
          }
        end)
    })
  end

  defp format_set(detail) do
    compact(%{
      set: detail.set,
      side: side(detail.side),
      reps: num(detail.reps),
      weight: num(detail.weight),
      rir: if(detail.rir not in [nil, 0.0], do: num(detail.rir)),
      rpe: num(detail.rpe),
      status:
        if(detail.progression_status not in [nil, "hold", "none"], do: detail.progression_status)
    })
  end

  defp side("both"), do: nil
  defp side(other), do: other

  defp num(nil), do: nil
  defp num(n) when is_float(n) and n == trunc(n), do: trunc(n)
  defp num(n), do: n

  defp format_date(%DateTime{} = dt), do: dt |> DateTime.to_date() |> Date.to_iso8601()
  defp format_date(%NaiveDateTime{} = dt), do: dt |> NaiveDateTime.to_date() |> Date.to_iso8601()
  defp format_date(_), do: nil

  defp compact(map) do
    map
    |> Enum.reject(fn {_k, v} -> is_nil(v) or v == [] end)
    |> Map.new()
  end

  # --- helpers ---------------------------------------------------------------

  defp require_write(%{token: nil}), do: :ok

  defp require_write(%{token: token}) do
    if ApiTokens.can_write?(token),
      do: :ok,
      else:
        {:error,
         "This token is read-only. Create a \"Read and write\" API token at /client/settings/api-tokens to log workouts."}
  end

  defp require_string(value, _field) when is_binary(value) and value != "", do: :ok
  defp require_string(_value, field), do: {:error, "#{field} is required."}

  defp require_int(value, field) do
    case parse_int(value) do
      n when is_integer(n) -> {:ok, n}
      _ -> {:error, "#{field} must be an integer."}
    end
  end

  defp parse_int(value) when is_integer(value), do: value
  defp parse_int(value) when is_float(value) and value == trunc(value), do: trunc(value)

  defp parse_int(value) when is_binary(value) do
    case Integer.parse(String.trim(value)) do
      {n, ""} -> n
      _ -> nil
    end
  end

  defp parse_int(_), do: nil

  defp clamp(value, min, max, default) do
    case parse_int(value) do
      n when is_integer(n) -> n |> max(min) |> min(max)
      _ -> default
    end
  end

  # A bare date is stored at midday UTC, so it shows on the same calendar day
  # in any timezone within twelve hours of UTC.
  defp parse_date(nil), do: {:ok, DateTime.utc_now() |> DateTime.truncate(:second)}

  defp parse_date(value) when is_binary(value) do
    case Date.from_iso8601(value) do
      {:ok, date} ->
        {:ok, DateTime.new!(date, ~T[12:00:00], "Etc/UTC")}

      _ ->
        case DateTime.from_iso8601(value) do
          {:ok, dt, _offset} -> {:ok, DateTime.truncate(dt, :second)}
          _ -> {:error, "date must be YYYY-MM-DD or an ISO 8601 datetime."}
        end
    end
  end

  defp parse_date(_), do: {:error, "date must be YYYY-MM-DD or an ISO 8601 datetime."}

  defp changeset_error({:error, %Ecto.Changeset{} = changeset}) do
    message =
      changeset
      |> Ecto.Changeset.traverse_errors(fn {msg, opts} ->
        Enum.reduce(opts, msg, fn {key, value}, acc ->
          String.replace(acc, "%{#{key}}", to_string(value))
        end)
      end)
      |> Enum.map_join("; ", fn {field, msgs} ->
        "#{field}: #{Enum.join(List.wrap(msgs), ", ")}"
      end)

    {:error, "Not saved: " <> message}
  end

  defp changeset_error({:error, other}) when not is_binary(other),
    do: {:error, "Not saved: #{inspect(other)}"}

  defp changeset_error(result), do: result
end
