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
alias Crohnjobs.Workout.Exercise

exercises = [
  # BACK
  %{name: "Deadlift", type: "Back", equipment: "Barbell"},
  %{name: "Conventional Deadlift", type: "Back", equipment: "Barbell"},
  %{name: "Barbell Bent Over Row", type: "Back", equipment: "Barbell"},
  %{name: "Dumbbell Row (One Arm)", type: "Back", equipment: "Dumbbell"},
  %{name: "Wide Lat Pulldown", type: "Back", equipment: "Cable"},
  %{name: "Lat Pulldown", type: "Back", equipment: "Cable"},
  %{name: "Cable Row", type: "Back", equipment: "Cable"},
  %{name: "Wide Grip Cable Row", type: "Back", equipment: "Cable"},
  %{name: "Machine Pullover", type: "Back", equipment: "Machine"},
  %{name: "Dumbbell Pullover", type: "Back", equipment: "Dumbbell"},
  %{name: "Seated Row", type: "Back", equipment: "Machine"},

  # HAMSTRINGS
  %{name: "Romanian Deadlift", type: "Hamstrings", equipment: "Barbell"},
  %{name: "Lying Leg Curl", type: "Hamstrings", equipment: "Machine"},
  %{name: "Seated Leg Curl", type: "Hamstrings", equipment: "Machine"},
  %{name: "Seated Machine Hinge", type: "Hamstrings", equipment: "Machine"},

  # SHOULDERS
  %{name: "Overhead Press", type: "Shoulders", equipment: "Barbell"},
  %{name: "Dumbbell Shoulder Press", type: "Shoulders", equipment: "Dumbbell"},
  %{name: "Lateral Raise", type: "Shoulders", equipment: "Dumbbell"},
  %{name: "Cable Lateral Raise", type: "Shoulders", equipment: "Cable"},
  %{name: "Reverse Fly", type: "Shoulders", equipment: "Dumbbell"},
  %{name: "One Arm Reverse Fly", type: "Shoulders", equipment: "Dumbbell"},
  %{name: "Front Raise", type: "Shoulders", equipment: "Dumbbell"},
  %{name: "Arnold Press", type: "Shoulders", equipment: "Dumbbell"},
  %{name: "Face Pull", type: "Rear Delts", equipment: "Cable"},

  # CHEST
  %{name: "Barbell Bench Press", type: "Chest", equipment: "Barbell"},
  %{name: "Incline Barbell Press", type: "Chest", equipment: "Barbell"},
  %{name: "Decline Barbell Press", type: "Chest", equipment: "Barbell"},
  %{name: "Dumbbell Bench Press", type: "Chest", equipment: "Dumbbell"},
  %{name: "Incline Dumbbell Press", type: "Chest", equipment: "Dumbbell"},
  %{name: "Decline Dumbbell Press", type: "Chest", equipment: "Dumbbell"},
  %{name: "Dumbbell Fly", type: "Chest", equipment: "Dumbbell"},
  %{name: "Cable Chest Fly", type: "Chest", equipment: "Cable"},
  %{name: "Machine Chest Press", type: "Chest", equipment: "Machine"},
  %{name: "Incline Machine Chest Press", type: "Chest", equipment: "Machine"},

  # BICEPS
  %{name: "Barbell Curl", type: "Biceps", equipment: "Barbell"},
  %{name: "Preacher Curl", type: "Biceps", equipment: "Machine"},
  %{name: "Hammer Curl", type: "Biceps", equipment: "Dumbbell"},
  %{name: "Incline Dumbbell Curl", type: "Biceps", equipment: "Dumbbell"},
  %{name: "Bayesian Curl", type: "Biceps", equipment: "Cable"},

  # TRICEPS
  %{name: "Tricep Pushdown", type: "Triceps", equipment: "Cable"},
  %{name: "Tricep Cable Kickback", type: "Triceps", equipment: "Cable"},
  %{name: "Skull Crusher", type: "Triceps", equipment: "Barbell"},
  %{name: "JM Press", type: "Triceps", equipment: "Barbell"},

  # CALVES
  %{name: "Standing Calf Raise", type: "Calves", equipment: "Machine"},
  %{name: "Seated Calf Raise", type: "Calves", equipment: "Machine"},
  %{name: "Leg Press Calf Raise", type: "Calves", equipment: "Machine"},

  # ABS (just a few defaults)
  %{name: "Cable Crunch", type: "Abs", equipment: "Cable"},
  %{name: "Plank", type: "Abs", equipment: "Bodyweight"},
  %{name: "Leg Raise", type: "Abs", equipment: "Bodyweight"}
]
Enum.each(exercises, fn attrs ->
  Repo.insert!(%Exercise{} |> Exercise.changeset(attrs))
end)
