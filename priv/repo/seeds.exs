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
alias Crohnjobs.Account.User
alias Crohnjobs.Trainers.Trainer
alias Crohnjobs.Clients.Client
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
  "Calves",
  "Hip Adductors",
  "Hip Abductors"
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


# ── Seed Users, Trainers, and Clients ──────────────────────────────

# Create a trainer user
trainer_user =
  %User{}
  |> User.registration_changeset(%{
    name: "Ebrahim Arshad",
    email: "ebrahim@scopestrength.com",
    password: "Abdevilliers15*",
    role: "trainer"
  })
  |> Repo.insert!()

# Create the trainer profile
trainer =
  %Trainer{}
  |> Trainer.changeset(%{
    user_id: trainer_user.id,
    bio: "Experienced fitness trainer specializing in strength training",
    specialization: "Strength & Conditioning"
  })
  |> Repo.insert!()

# Create a client user
client_user =
  %User{}
  |> User.registration_changeset(%{
    name: "Ebrahim",
    email: "ebbibest@gmail.com",
    password: "Abdevilliers15*",
    role: "client"
  })
  |> Repo.insert!()

# Create the client profile
client =
  %Client{}
  |> Client.changeset(%{
    user_id: client_user.id,
    trainer_id: trainer.id,
    age: 30,
    height: Decimal.new("175.5"),
    sex: "male",
    active: true,
    notes: "New client, beginner level"
  })
  |> Repo.insert!()

# Create another client user
client_user_2 =
  %User{}
  |> User.registration_changeset(%{
    name: "Jane Smith",
    email: "jane@example.com",
    password: "securepassword123",
    role: "client"
  })
  |> Repo.insert!()

# Create the second client profile
client_2 =
  %Client{}
  |> Client.changeset(%{
    user_id: client_user_2.id,
    trainer_id: trainer.id,
    age: 28,
    height: Decimal.new("165.0"),
    sex: "female",
    active: true,
    notes: "Intermediate level, focus on muscle building"
  })
  |> Repo.insert!()

equipment =
  Enum.into(equipment_names, %{}, fn name ->
    equip = Repo.insert!(%Equipment{name: name})
    {name, equip.id}
  end)



# ── Seed exercises ──────────────────────────────────────────────────
exercises = [
  # GLUTES
  %{name: "Deadlift", muscle: "Glutes", equipment: "Barbell"},
  %{name: "Conventional Deadlift", muscle: "Glutes", equipment: "Barbell"},
  %{name: "Hip Thrust", muscle: "Glutes", equipment: "Barbell"},
  %{name: "Cable Pull Through", muscle: "Glutes", equipment: "Cable"},

  # LATS
  %{name: "Wide Lat Pulldown", muscle: "Lats", equipment: "Cable"},
  %{name: "Lat Pulldown", muscle: "Lats", equipment: "Cable"},
  %{name: "Lat Prayer", muscle: "Lats", equipment: "Cable"},
  %{name: "Machine Pullover", muscle: "Lats", equipment: "Machine"},
  %{name: "Dumbbell Pullover", muscle: "Lats", equipment: "Dumbbell"},
  %{name: "Pull Up", muscle: "Lats", equipment: "Bodyweight"},
  %{name: "Chin Up", muscle: "Lats", equipment: "Bodyweight"},

  # UPPER BACK
  %{name: "Barbell Bent Over Row", muscle: "Upper Back", equipment: "Barbell"},
  %{name: "Dumbbell Row (One Arm)", muscle: "Upper Back", equipment: "Dumbbell", is_unilateral: true},
  %{name: "Cable Row", muscle: "Upper Back", equipment: "Cable"},
  %{name: "Wide Grip Cable Row", muscle: "Upper Back", equipment: "Cable"},
  %{name: "Seated Row", muscle: "Upper Back", equipment: "Machine"},

  # QUADS
  %{name: "Barbell Squat", muscle: "Quads", equipment: "Barbell"},
  %{name: "Front Squat", muscle: "Quads", equipment: "Barbell"},
  %{name: "Leg Press", muscle: "Quads", equipment: "Machine"},
  %{name: "Hack Squat", muscle: "Quads", equipment: "Machine"},
  %{name: "Leg Extension", muscle: "Quads", equipment: "Machine"},
  %{name: "Bulgarian Split Squat", muscle: "Quads", equipment: "Dumbbell", is_unilateral: true},
  %{name: "Lunges", muscle: "Quads", equipment: "Dumbbell", is_unilateral: true},
  %{name: "Single Leg Extension", muscle: "Quads", equipment: "Machine", is_unilateral: true},
  %{name: "Reverse Lunges", muscle: "Quads", equipment: "Dumbbell", is_unilateral: true},
  %{name: "Sissy Squat", muscle: "Quads", equipment: "Bodyweight"},

  # HAMSTRINGS
  %{name: "Romanian Deadlift", muscle: "Hamstrings", equipment: "Barbell"},
  %{name: "Lying Leg Curl", muscle: "Hamstrings", equipment: "Machine"},
  %{name: "Seated Leg Curl", muscle: "Hamstrings", equipment: "Machine"},
  %{name: "Seated Machine Hinge", muscle: "Hamstrings", equipment: "Machine"},
  %{name: "Good Mornings", muscle: "Hamstrings", equipment: "Barbell"},
  %{name: "Single Leg Deadlift", muscle: "Hamstrings", equipment: "Dumbbell", is_unilateral: true},
  %{name: "Back Extension", muscle: "Hamstrings", equipment: "Bodyweight"},

  # FRONT DELTS
  %{name: "Overhead Press", muscle: "Front Delts", equipment: "Barbell"},
  %{name: "Dumbbell Shoulder Press", muscle: "Front Delts", equipment: "Dumbbell"},
  %{name: "Front Raise", muscle: "Front Delts", equipment: "Dumbbell"},
  %{name: "Arnold Press", muscle: "Front Delts", equipment: "Dumbbell"},

  # SIDE DELTS
  %{name: "Lateral Raise", muscle: "Side Delts", equipment: "Dumbbell"},
  %{name: "Cable Lateral Raise", muscle: "Side Delts", equipment: "Cable"},
  %{name: "Cable Laterals (One)", muscle: "Side Delts", equipment: "Cable", is_unilateral: true},

  # REAR DELTS
  %{name: "Reverse Fly", muscle: "Rear Delts", equipment: "Dumbbell"},
  %{name: "One Arm Reverse Fly", muscle: "Rear Delts", equipment: "Dumbbell", is_unilateral: true},
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
  %{name: "Recline Preacher Curl", muscle: "Biceps", equipment: "Dumbbell"},

  # TRICEPS
  %{name: "Tricep Pushdown", muscle: "Triceps", equipment: "Cable"},
  %{name: "Tricep Pushdown (One Arm)", muscle: "Triceps", equipment: "Cable", is_unilateral: true},
  %{name: "Tricep Cable Kickback", muscle: "Triceps", equipment: "Cable"},
  %{name: "Skull Crusher", muscle: "Triceps", equipment: "Barbell"},
  %{name: "JM Press", muscle: "Triceps", equipment: "Barbell"},
  %{name: "Close Grip Bench Press", muscle: "Triceps", equipment: "Barbell"},
  %{name: "Bodyweight Dips", muscle: "Triceps", equipment: "Bodyweight"},

  # CALVES
  %{name: "Standing Calf Raise", muscle: "Calves", equipment: "Machine"},
  %{name: "Seated Calf Raise", muscle: "Calves", equipment: "Machine"},
  %{name: "Leg Press Calf Raise", muscle: "Calves", equipment: "Machine"},

  # ABS
  %{name: "Cable Crunch", muscle: "Abs", equipment: "Cable"},
  %{name: "Plank", muscle: "Abs", equipment: "Bodyweight"},
  %{name: "Leg Raise", muscle: "Abs", equipment: "Bodyweight"},

  # HIP ADDUCTORS
  %{name: "Hip Adduction Machine", muscle: "Hip Adductors", equipment: "Machine"},
  %{name: "Cable Hip Adduction", muscle: "Hip Adductors", equipment: "Cable", is_unilateral: true},

  # HIP ABDUCTORS
  %{name: "Hip Abduction Machine", muscle: "Hip Abductors", equipment: "Machine"},
  %{name: "Cable Hip Abduction", muscle: "Hip Abductors", equipment: "Cable", is_unilateral: true}
]

# Insert exercises and build exercise_map
exercise_map =
  Enum.into(exercises, %{}, fn attrs ->
    ex =
      %Exercise{}
      |> Exercise.changeset(%{
        name: attrs.name,
        muscle_id: muscles[attrs.muscle],
        equipment_id: equipment[attrs.equipment],
        is_unilateral: Map.get(attrs, :is_unilateral, false)
      })
      |> Repo.insert!()

    {attrs.name, ex}
  end)

# ── Seed exercise muscle contributions ──────────────────────────────
# Multiplier system:
#   - Primary: 1.0 (target muscle)
#   - Secondary: 0.5 (assists the movement)

contributions = [
  # ═══════════════════════════════════════════════════════════════════
  # CHEST EXERCISES
  # ═══════════════════════════════════════════════════════════════════

  # Barbell Bench Press
  %{exercise: "Barbell Bench Press", muscle: "Chest", role: "primary", multiplier: 1.0},
  %{exercise: "Barbell Bench Press", muscle: "Triceps", role: "secondary", multiplier: 0.5},
  %{exercise: "Barbell Bench Press", muscle: "Front Delts", role: "secondary", multiplier: 0.5},

  # Incline Barbell Press
  %{exercise: "Incline Barbell Press", muscle: "Chest", role: "primary", multiplier: 1.0},
  %{exercise: "Incline Barbell Press", muscle: "Front Delts", role: "secondary", multiplier: 0.5},
  %{exercise: "Incline Barbell Press", muscle: "Triceps", role: "secondary", multiplier: 0.5},

  # Decline Barbell Press
  %{exercise: "Decline Barbell Press", muscle: "Chest", role: "primary", multiplier: 1.0},
  %{exercise: "Decline Barbell Press", muscle: "Triceps", role: "secondary", multiplier: 0.5},

  # Dumbbell Bench Press
  %{exercise: "Dumbbell Bench Press", muscle: "Chest", role: "primary", multiplier: 1.0},
  %{exercise: "Dumbbell Bench Press", muscle: "Triceps", role: "secondary", multiplier: 0.5},
  %{exercise: "Dumbbell Bench Press", muscle: "Front Delts", role: "secondary", multiplier: 0.5},

  # Incline Dumbbell Press
  %{exercise: "Incline Dumbbell Press", muscle: "Chest", role: "primary", multiplier: 1.0},
  %{exercise: "Incline Dumbbell Press", muscle: "Front Delts", role: "secondary", multiplier: 0.5},
  %{exercise: "Incline Dumbbell Press", muscle: "Triceps", role: "secondary", multiplier: 0.5},

  # Decline Dumbbell Press
  %{exercise: "Decline Dumbbell Press", muscle: "Chest", role: "primary", multiplier: 1.0},
  %{exercise: "Decline Dumbbell Press", muscle: "Triceps", role: "secondary", multiplier: 0.5},

  # Dumbbell Fly (isolation - primary only)
  %{exercise: "Dumbbell Fly", muscle: "Chest", role: "primary", multiplier: 1.0},

  # Cable Chest Fly (isolation - primary only)
  %{exercise: "Cable Chest Fly", muscle: "Chest", role: "primary", multiplier: 1.0},

  # Machine Chest Press
  %{exercise: "Machine Chest Press", muscle: "Chest", role: "primary", multiplier: 1.0},
  %{exercise: "Machine Chest Press", muscle: "Triceps", role: "secondary", multiplier: 0.5},

  # Incline Machine Chest Press
  %{exercise: "Incline Machine Chest Press", muscle: "Chest", role: "primary", multiplier: 1.0},
  %{exercise: "Incline Machine Chest Press", muscle: "Front Delts", role: "secondary", multiplier: 0.5},

  # ═══════════════════════════════════════════════════════════════════
  # GLUTES EXERCISES
  # ═══════════════════════════════════════════════════════════════════

  # Deadlift
  %{exercise: "Deadlift", muscle: "Glutes", role: "primary", multiplier: 1.0},
  %{exercise: "Deadlift", muscle: "Hamstrings", role: "secondary", multiplier: 0.5},
  %{exercise: "Deadlift", muscle: "Lats", role: "secondary", multiplier: 0.5},

  # Conventional Deadlift
  %{exercise: "Conventional Deadlift", muscle: "Glutes", role: "primary", multiplier: 1.0},
  %{exercise: "Conventional Deadlift", muscle: "Hamstrings", role: "secondary", multiplier: 0.5},
  %{exercise: "Conventional Deadlift", muscle: "Lats", role: "secondary", multiplier: 0.5},

  # Hip Thrust
  %{exercise: "Hip Thrust", muscle: "Glutes", role: "primary", multiplier: 1.0},
  %{exercise: "Hip Thrust", muscle: "Hamstrings", role: "secondary", multiplier: 0.5},

  # Cable Pull Through
  %{exercise: "Cable Pull Through", muscle: "Glutes", role: "primary", multiplier: 1.0},
  %{exercise: "Cable Pull Through", muscle: "Hamstrings", role: "secondary", multiplier: 0.5},

  # ═══════════════════════════════════════════════════════════════════
  # LATS EXERCISES
  # ═══════════════════════════════════════════════════════════════════

  # Wide Lat Pulldown
  %{exercise: "Wide Lat Pulldown", muscle: "Lats", role: "primary", multiplier: 1.0},
  %{exercise: "Wide Lat Pulldown", muscle: "Biceps", role: "secondary", multiplier: 0.5},

  # Lat Pulldown
  %{exercise: "Lat Pulldown", muscle: "Lats", role: "primary", multiplier: 1.0},
  %{exercise: "Lat Pulldown", muscle: "Biceps", role: "secondary", multiplier: 0.5},

  # Machine Pullover
  %{exercise: "Machine Pullover", muscle: "Lats", role: "primary", multiplier: 1.0},

  # Dumbbell Pullover
  %{exercise: "Dumbbell Pullover", muscle: "Lats", role: "primary", multiplier: 1.0},

  # Pull Up
  %{exercise: "Pull Up", muscle: "Lats", role: "primary", multiplier: 1.0},
  %{exercise: "Pull Up", muscle: "Biceps", role: "secondary", multiplier: 0.5},

  # Chin Up
  %{exercise: "Chin Up", muscle: "Lats", role: "primary", multiplier: 1.0},
  %{exercise: "Chin Up", muscle: "Biceps", role: "secondary", multiplier: 0.5},

  # Lat Prayer (isolation)
  %{exercise: "Lat Prayer", muscle: "Lats", role: "primary", multiplier: 1.0},

  # ═══════════════════════════════════════════════════════════════════
  # UPPER BACK EXERCISES
  # ═══════════════════════════════════════════════════════════════════

  # Barbell Bent Over Row
  %{exercise: "Barbell Bent Over Row", muscle: "Upper Back", role: "primary", multiplier: 1.0},
  %{exercise: "Barbell Bent Over Row", muscle: "Lats", role: "secondary", multiplier: 0.5},
  %{exercise: "Barbell Bent Over Row", muscle: "Biceps", role: "secondary", multiplier: 0.5},

  # Dumbbell Row (One Arm)
  %{exercise: "Dumbbell Row (One Arm)", muscle: "Upper Back", role: "primary", multiplier: 1.0},
  %{exercise: "Dumbbell Row (One Arm)", muscle: "Lats", role: "secondary", multiplier: 0.5},
  %{exercise: "Dumbbell Row (One Arm)", muscle: "Biceps", role: "secondary", multiplier: 0.5},

  # Cable Row
  %{exercise: "Cable Row", muscle: "Upper Back", role: "primary", multiplier: 1.0},
  %{exercise: "Cable Row", muscle: "Lats", role: "secondary", multiplier: 0.5},
  %{exercise: "Cable Row", muscle: "Biceps", role: "secondary", multiplier: 0.5},

  # Wide Grip Cable Row
  %{exercise: "Wide Grip Cable Row", muscle: "Upper Back", role: "primary", multiplier: 1.0},
  %{exercise: "Wide Grip Cable Row", muscle: "Rear Delts", role: "secondary", multiplier: 0.5},

  # Seated Row
  %{exercise: "Seated Row", muscle: "Upper Back", role: "primary", multiplier: 1.0},
  %{exercise: "Seated Row", muscle: "Lats", role: "secondary", multiplier: 0.5},
  %{exercise: "Seated Row", muscle: "Biceps", role: "secondary", multiplier: 0.5},

  # ═══════════════════════════════════════════════════════════════════
  # QUADS EXERCISES
  # ═══════════════════════════════════════════════════════════════════

  # Barbell Squat
  %{exercise: "Barbell Squat", muscle: "Quads", role: "primary", multiplier: 1.0},
  %{exercise: "Barbell Squat", muscle: "Glutes", role: "secondary", multiplier: 0.5},

  # Front Squat
  %{exercise: "Front Squat", muscle: "Quads", role: "primary", multiplier: 1.0},

  # Leg Press
  %{exercise: "Leg Press", muscle: "Quads", role: "primary", multiplier: 1.0},
  %{exercise: "Leg Press", muscle: "Glutes", role: "secondary", multiplier: 0.5},

  # Hack Squat
  %{exercise: "Hack Squat", muscle: "Quads", role: "primary", multiplier: 1.0},
  %{exercise: "Hack Squat", muscle: "Glutes", role: "secondary", multiplier: 0.5},

  # Leg Extension (isolation)
  %{exercise: "Leg Extension", muscle: "Quads", role: "primary", multiplier: 1.0},

  # Bulgarian Split Squat
  %{exercise: "Bulgarian Split Squat", muscle: "Quads", role: "primary", multiplier: 1.0},
  %{exercise: "Bulgarian Split Squat", muscle: "Glutes", role: "secondary", multiplier: 0.5},

  # Lunges
  %{exercise: "Lunges", muscle: "Quads", role: "primary", multiplier: 1.0},
  %{exercise: "Lunges", muscle: "Glutes", role: "secondary", multiplier: 0.5},

  # Single Leg Extension (isolation)
  %{exercise: "Single Leg Extension", muscle: "Quads", role: "primary", multiplier: 1.0},

  # Reverse Lunges
  %{exercise: "Reverse Lunges", muscle: "Quads", role: "primary", multiplier: 1.0},
  %{exercise: "Reverse Lunges", muscle: "Glutes", role: "secondary", multiplier: 0.5},

  # Sissy Squat (isolation)
  %{exercise: "Sissy Squat", muscle: "Quads", role: "primary", multiplier: 1.0},

  # ═══════════════════════════════════════════════════════════════════
  # HAMSTRINGS EXERCISES
  # ═══════════════════════════════════════════════════════════════════

  # Romanian Deadlift
  %{exercise: "Romanian Deadlift", muscle: "Hamstrings", role: "primary", multiplier: 1.0},
  %{exercise: "Romanian Deadlift", muscle: "Glutes", role: "secondary", multiplier: 0.5},

  # Lying Leg Curl (isolation)
  %{exercise: "Lying Leg Curl", muscle: "Hamstrings", role: "primary", multiplier: 1.0},

  # Seated Leg Curl (isolation)
  %{exercise: "Seated Leg Curl", muscle: "Hamstrings", role: "primary", multiplier: 1.0},

  # Seated Machine Hinge
  %{exercise: "Seated Machine Hinge", muscle: "Hamstrings", role: "primary", multiplier: 1.0},
  %{exercise: "Seated Machine Hinge", muscle: "Glutes", role: "secondary", multiplier: 0.5},

  # Good Mornings
  %{exercise: "Good Mornings", muscle: "Hamstrings", role: "primary", multiplier: 1.0},
  %{exercise: "Good Mornings", muscle: "Glutes", role: "secondary", multiplier: 0.5},

  # Single Leg Deadlift
  %{exercise: "Single Leg Deadlift", muscle: "Hamstrings", role: "primary", multiplier: 1.0},
  %{exercise: "Single Leg Deadlift", muscle: "Glutes", role: "secondary", multiplier: 0.5},

  # Back Extension
  %{exercise: "Back Extension", muscle: "Hamstrings", role: "primary", multiplier: 1.0},
  %{exercise: "Back Extension", muscle: "Glutes", role: "secondary", multiplier: 0.5},

  # ═══════════════════════════════════════════════════════════════════
  # FRONT DELTS EXERCISES
  # ═══════════════════════════════════════════════════════════════════

  # Overhead Press
  %{exercise: "Overhead Press", muscle: "Front Delts", role: "primary", multiplier: 1.0},
  %{exercise: "Overhead Press", muscle: "Triceps", role: "secondary", multiplier: 0.5},

  # Dumbbell Shoulder Press
  %{exercise: "Dumbbell Shoulder Press", muscle: "Front Delts", role: "primary", multiplier: 1.0},
  %{exercise: "Dumbbell Shoulder Press", muscle: "Triceps", role: "secondary", multiplier: 0.5},

  # Front Raise (isolation)
  %{exercise: "Front Raise", muscle: "Front Delts", role: "primary", multiplier: 1.0},

  # Arnold Press
  %{exercise: "Arnold Press", muscle: "Front Delts", role: "primary", multiplier: 1.0},
  %{exercise: "Arnold Press", muscle: "Side Delts", role: "secondary", multiplier: 0.5},
  %{exercise: "Arnold Press", muscle: "Triceps", role: "secondary", multiplier: 0.5},

  # ═══════════════════════════════════════════════════════════════════
  # SIDE DELTS EXERCISES
  # ═══════════════════════════════════════════════════════════════════

  # Lateral Raise (isolation)
  %{exercise: "Lateral Raise", muscle: "Side Delts", role: "primary", multiplier: 1.0},

  # Cable Lateral Raise (isolation)
  %{exercise: "Cable Lateral Raise", muscle: "Side Delts", role: "primary", multiplier: 1.0},

  # Cable Laterals (One) (isolation)
  %{exercise: "Cable Laterals (One)", muscle: "Side Delts", role: "primary", multiplier: 1.0},

  # ═══════════════════════════════════════════════════════════════════
  # REAR DELTS EXERCISES
  # ═══════════════════════════════════════════════════════════════════

  # Reverse Fly
  %{exercise: "Reverse Fly", muscle: "Rear Delts", role: "primary", multiplier: 1.0},
  %{exercise: "Reverse Fly", muscle: "Upper Back", role: "secondary", multiplier: 0.5},

  # One Arm Reverse Fly
  %{exercise: "One Arm Reverse Fly", muscle: "Rear Delts", role: "primary", multiplier: 1.0},
  %{exercise: "One Arm Reverse Fly", muscle: "Upper Back", role: "secondary", multiplier: 0.5},

  # Face Pull
  %{exercise: "Face Pull", muscle: "Rear Delts", role: "primary", multiplier: 1.0},
  %{exercise: "Face Pull", muscle: "Upper Back", role: "secondary", multiplier: 0.5},

  # ═══════════════════════════════════════════════════════════════════
  # BICEPS EXERCISES (all isolation)
  # ═══════════════════════════════════════════════════════════════════

  %{exercise: "Barbell Curl", muscle: "Biceps", role: "primary", multiplier: 1.0},
  %{exercise: "Preacher Curl", muscle: "Biceps", role: "primary", multiplier: 1.0},
  %{exercise: "Hammer Curl", muscle: "Biceps", role: "primary", multiplier: 1.0},
  %{exercise: "Incline Dumbbell Curl", muscle: "Biceps", role: "primary", multiplier: 1.0},
  %{exercise: "Bayesian Curl", muscle: "Biceps", role: "primary", multiplier: 1.0},
  %{exercise: "Recline Preacher Curl", muscle: "Biceps", role: "primary", multiplier: 1.0},

  # ═══════════════════════════════════════════════════════════════════
  # TRICEPS EXERCISES (all isolation)
  # ═══════════════════════════════════════════════════════════════════

  %{exercise: "Tricep Pushdown", muscle: "Triceps", role: "primary", multiplier: 1.0},
  %{exercise: "Tricep Pushdown (One Arm)", muscle: "Triceps", role: "primary", multiplier: 1.0},
  %{exercise: "Tricep Cable Kickback", muscle: "Triceps", role: "primary", multiplier: 1.0},
  %{exercise: "Skull Crusher", muscle: "Triceps", role: "primary", multiplier: 1.0},
  %{exercise: "JM Press", muscle: "Triceps", role: "primary", multiplier: 1.0},

  # Close Grip Bench Press
  %{exercise: "Close Grip Bench Press", muscle: "Triceps", role: "primary", multiplier: 1.0},
  %{exercise: "Close Grip Bench Press", muscle: "Chest", role: "secondary", multiplier: 0.5},

  # Bodyweight Dips
  %{exercise: "Bodyweight Dips", muscle: "Triceps", role: "primary", multiplier: 1.0},
  %{exercise: "Bodyweight Dips", muscle: "Chest", role: "secondary", multiplier: 0.5},

  # ═══════════════════════════════════════════════════════════════════
  # CALVES EXERCISES (all isolation)
  # ═══════════════════════════════════════════════════════════════════

  %{exercise: "Standing Calf Raise", muscle: "Calves", role: "primary", multiplier: 1.0},
  %{exercise: "Seated Calf Raise", muscle: "Calves", role: "primary", multiplier: 1.0},
  %{exercise: "Leg Press Calf Raise", muscle: "Calves", role: "primary", multiplier: 1.0},

  # ═══════════════════════════════════════════════════════════════════
  # ABS EXERCISES (all isolation)
  # ═══════════════════════════════════════════════════════════════════

  %{exercise: "Cable Crunch", muscle: "Abs", role: "primary", multiplier: 1.0},
  %{exercise: "Plank", muscle: "Abs", role: "primary", multiplier: 1.0},
  %{exercise: "Leg Raise", muscle: "Abs", role: "primary", multiplier: 1.0},

  # ═══════════════════════════════════════════════════════════════════
  # HIP ADDUCTORS EXERCISES (all isolation)
  # ═══════════════════════════════════════════════════════════════════

  %{exercise: "Hip Adduction Machine", muscle: "Hip Adductors", role: "primary", multiplier: 1.0},
  %{exercise: "Cable Hip Adduction", muscle: "Hip Adductors", role: "primary", multiplier: 1.0},

  # ═══════════════════════════════════════════════════════════════════
  # HIP ABDUCTORS EXERCISES (all isolation)
  # ═══════════════════════════════════════════════════════════════════

  %{exercise: "Hip Abduction Machine", muscle: "Hip Abductors", role: "primary", multiplier: 1.0},
  %{exercise: "Cable Hip Abduction", muscle: "Hip Abductors", role: "primary", multiplier: 1.0}
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

# ── Seed set types ──────────────────────────────────────────────────
alias Crohnjobs.Training.SetType

set_types = [
  %{name: "Standard", description: "Regular set with prescribed reps and weight"},
  %{name: "AMRAP", description: "As Many Reps As Possible - push to maximum reps"},
  %{name: "Drop Set", description: "Reduce weight and continue after failure"},
  %{name: "Rest Pause", description: "Brief rest periods within a single set"},
  %{name: "Cluster Set", description: "Short rest between mini-sets"},
  %{name: "Myo-reps", description: "Activation set followed by low-rep sets"},
  %{name: "To Failure", description: "Continue until unable to complete another rep"},
  %{name: "Tempo", description: "Controlled tempo, specified in notes"},
  %{name: "Superset", description: "Paired with another exercise, minimal rest"}
]

Enum.each(set_types, fn attrs ->
  %SetType{}
  |> SetType.changeset(attrs)
  |> Repo.insert!()
end)
