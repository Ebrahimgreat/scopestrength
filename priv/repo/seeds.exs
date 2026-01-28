# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Crohnjobs.Repo.insert!(%Crohnjobs.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
alias Crohnjobs.Repo
alias Crohnjobs.Exercises.{Exercise, Muscles, Equipment}
alias Crohnjobs.Exercises.ExerciseMuscleContribution

# ── Seed muscle groups ──────────────────────────────────────────────
muscle_names = [
  "Chest",
  "Upper Back",
  "Lats",
  "Quads",
  "Side Delts",
  "Front Delts",
  "Hamstrings",
  "Glutes",
  "Rear Delts",
  "Abs",
  "Biceps",
  "Triceps",
  "Calves"
]

muscles =
  Enum.into(muscle_names, %{}, fn name ->
    muscle = Repo.insert!(%Muscles{name: name})
    {name, muscle.id}
  end)

# ── Seed equipment ──────────────────────────────────────────────────
equipment_names = [
  "Barbell",
  "Dumbbell",
  "Cable",
  "Machine",
  "Plate",
  "Bodyweight"
]

equipment =
  Enum.into(equipment_names, %{}, fn name ->
    equip = Repo.insert!(%Equipment{name: name})
    {name, equip.id}
  end)



# ── Seed exercises ──────────────────────────────────────────────────
exercises = [
  # LATS
  %{name: "Deadlift", muscle: "Lats", equipment: "Barbell"},
  %{name: "Conventional Deadlift", muscle: "Lats", equipment: "Barbell"},
  %{name: "Wide Lat Pulldown", muscle: "Lats", equipment: "Cable"},
  %{name: "Lat Pulldown", muscle: "Lats", equipment: "Cable"},
  %{name: "Machine Pullover", muscle: "Lats", equipment: "Machine"},
  %{name: "Dumbbell Pullover", muscle: "Lats", equipment: "Dumbbell"},

  # UPPER BACK
  %{name: "Barbell Bent Over Row", muscle: "Upper Back", equipment: "Barbell"},
  %{name: "Dumbbell Row (One Arm)", muscle: "Upper Back", equipment: "Dumbbell"},
  %{name: "Cable Row", muscle: "Upper Back", equipment: "Cable"},
  %{name: "Wide Grip Cable Row", muscle: "Upper Back", equipment: "Cable"},
  %{name: "Seated Row", muscle: "Upper Back", equipment: "Machine"},

  # HAMSTRINGS
  %{name: "Romanian Deadlift", muscle: "Hamstrings", equipment: "Barbell"},
  %{name: "Lying Leg Curl", muscle: "Hamstrings", equipment: "Machine"},
  %{name: "Seated Leg Curl", muscle: "Hamstrings", equipment: "Machine"},
  %{name: "Seated Machine Hinge", muscle: "Hamstrings", equipment: "Machine"},

  # FRONT DELTS
  %{name: "Overhead Press", muscle: "Front Delts", equipment: "Barbell"},
  %{name: "Dumbbell Shoulder Press", muscle: "Front Delts", equipment: "Dumbbell"},
  %{name: "Front Raise", muscle: "Front Delts", equipment: "Dumbbell"},
  %{name: "Arnold Press", muscle: "Front Delts", equipment: "Dumbbell"},

  # SIDE DELTS
  %{name: "Lateral Raise", muscle: "Side Delts", equipment: "Dumbbell"},
  %{name: "Cable Lateral Raise", muscle: "Side Delts", equipment: "Cable"},

  # REAR DELTS
  %{name: "Reverse Fly", muscle: "Rear Delts", equipment: "Dumbbell"},
  %{name: "One Arm Reverse Fly", muscle: "Rear Delts", equipment: "Dumbbell"},
  %{name: "Face Pull", muscle: "Rear Delts", equipment: "Cable"},

  # CHEST
  %{name: "Barbell Bench Press", muscle: "Chest", equipment: "Barbell"},
  %{name: "Incline Barbell Press", muscle: "Chest", equipment: "Barbell"},
  %{name: "Decline Barbell Press", muscle: "Chest", equipment: "Barbell"},
  %{name: "Dumbbell Bench Press", muscle: "Chest", equipment: "Dumbbell"},
  %{name: "Incline Dumbbell Press", muscle: "Chest", equipment: "Dumbbell"},
  %{name: "Decline Dumbbell Press", muscle: "Chest", equipment: "Dumbbell"},
  %{name: "Dumbbell Fly", muscle: "Chest", equipment: "Dumbbell"},
  %{name: "Cable Chest Fly", muscle: "Chest", equipment: "Cable"},
  %{name: "Machine Chest Press", muscle: "Chest", equipment: "Machine"},
  %{name: "Incline Machine Chest Press", muscle: "Chest", equipment: "Machine"},

  # BICEPS
  %{name: "Barbell Curl", muscle: "Biceps", equipment: "Barbell"},
  %{name: "Preacher Curl", muscle: "Biceps", equipment: "Machine"},
  %{name: "Hammer Curl", muscle: "Biceps", equipment: "Dumbbell"},
  %{name: "Incline Dumbbell Curl", muscle: "Biceps", equipment: "Dumbbell"},
  %{name: "Bayesian Curl", muscle: "Biceps", equipment: "Cable"},

  # TRICEPS
  %{name: "Tricep Pushdown", muscle: "Triceps", equipment: "Cable"},
  %{name: "Tricep Cable Kickback", muscle: "Triceps", equipment: "Cable"},
  %{name: "Skull Crusher", muscle: "Triceps", equipment: "Barbell"},
  %{name: "JM Press", muscle: "Triceps", equipment: "Barbell"},

  # CALVES
  %{name: "Standing Calf Raise", muscle: "Calves", equipment: "Machine"},
  %{name: "Seated Calf Raise", muscle: "Calves", equipment: "Machine"},
  %{name: "Leg Press Calf Raise", muscle: "Calves", equipment: "Machine"},

  # ABS
  %{name: "Cable Crunch", muscle: "Abs", equipment: "Cable"},
  %{name: "Plank", muscle: "Abs", equipment: "Bodyweight"},
  %{name: "Leg Raise", muscle: "Abs", equipment: "Bodyweight"}
]

# Insert exercises and build exercise_map
exercise_map =
  Enum.into(exercises, %{}, fn attrs ->
    ex =
      %Exercise{}
      |> Exercise.changeset(%{
        name: attrs.name,
        muscle_id: muscles[attrs.muscle],
        equipment_id: equipment[attrs.equipment]
      })
      |> Repo.insert!()

    {attrs.name, ex}
  end)

# ── Seed exercise muscle contributions ──────────────────────────────
contributions = [
  %{exercise: "Dumbbell Bench Press", muscle: "Chest", role: "primary", multiplier: 1.0},
  %{exercise: "Dumbbell Bench Press", muscle: "Triceps", role: "secondary", multiplier: 0.3},
  %{exercise: "Dumbbell Bench Press", muscle: "Front Delts", role: "secondary", multiplier: 0.2},

  %{exercise: "Barbell Bench Press", muscle: "Chest", role: "primary", multiplier: 1.0},
  %{exercise: "Barbell Bench Press", muscle: "Triceps", role: "secondary", multiplier: 0.25},
  %{exercise: "Barbell Bench Press", muscle: "Front Delts", role: "secondary", multiplier: 0.2},

  %{exercise: "Barbell Bent Over Row", muscle: "Upper Back", role: "primary", multiplier: 1.0},
  %{exercise: "Barbell Bent Over Row", muscle: "Biceps", role: "secondary", multiplier: 0.3},

  %{exercise: "Lat Pulldown", muscle: "Lats", role: "primary", multiplier: 1.0},
  %{exercise: "Lat Pulldown", muscle: "Biceps", role: "secondary", multiplier: 0.25},

  %{exercise: "Barbell Curl", muscle: "Biceps", role: "primary", multiplier: 1.0}
]

Enum.each(contributions, fn attrs ->
  exercise = Map.fetch!(exercise_map, attrs.exercise)
  muscle_id =
    case Map.fetch(muscles, attrs.muscle) do
      {:ok, id} -> id
      :error -> raise "Muscle #{attrs.muscle} not found in muscles map"
    end

  Repo.insert!(%ExerciseMuscleContribution{}
    |> ExerciseMuscleContribution.changeset(%{
      exercise_id: exercise.id,
      muscle_id: muscle_id,
      role: attrs.role,
      multiplier: attrs.multiplier,
      trainer_id: nil
    })
  )
end)
