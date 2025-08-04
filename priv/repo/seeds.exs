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
  %{name: "Deadlift", type: "Back", equipment: "Barbell"},
  %{name: "Overhead Press", type: "Shoulders", equipment: "Barbell"},
  %{name: "Dumbbell Bench Press", type: "Chest", equipment: "Dumbbell"},
  %{name: "Bulgarian Split Squat", type: "Quads", equipment: "Dumbbell"},
  %{name: "Lat Pulldown", type: "Back", equipment: "Cable"},
  %{name: "Seated Row", type: "Back", equipment: "Machine"},
  %{name: "Leg Extension", type: "Quads", equipment: "Machine"},
  %{name: "Leg Curl", type: "Hamstrings", equipment: "Machine"},
  %{name: "Tricep Pushdown", type: "Triceps", equipment: "Cable"},
  %{name: "Barbell Curl", type: "Biceps", equipment: "Barbell"},
  %{name: "Preacher Curl", type: "Biceps", equipment: "Machine"},
  %{name: "Dumbbell Lateral Raise", type: "Shoulders", equipment: "Dumbbell"},
  %{name: "Face Pull", type: "Rear Delts", equipment: "Cable"},
  %{name: "Incline Dumbbell Press", type: "Chest", equipment: "Dumbbell"},
  %{name: "Chest Fly", type: "Chest", equipment: "Machine"},
  %{name: "Calf Raise", type: "Calves", equipment: "Machine"},
  %{name: "Hammer Curl", type: "Biceps", equipment: "Dumbbell"},
  %{name: "Front Squat", type: "Quads", equipment: "Barbell"},
  %{name: "Romanian Deadlift", type: "Hamstrings", equipment: "Barbell"},
  %{name: "Cable Crunch", type: "Abs", equipment: "Cable"}
]

Enum.each(exercises, fn attrs ->
  Repo.insert!(%Exercise{} |> Exercise.changeset(attrs))
end)
