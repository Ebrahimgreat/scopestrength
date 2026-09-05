alias Scopestrength.Repo
alias Scopestrength.Account.User
alias Scopestrength.Trainers.Trainer
alias Scopestrength.Clients.Client
alias Scopestrength.Exercises.{Exercise, Muscles, Equipment}
alias Scopestrength.Exercises.ExerciseMuscleContribution

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
  "Hip Abductors",
  "Forearms",
  "Traps",
  "Neck",
  "Lower Back",
  "Obliques"
]

muscles =
  Enum.into(muscle_names, %{}, fn name ->
    muscle = Repo.insert!(%Muscles{name: name})
    {name, muscle.id}
  end)

equipment_names = [
  "Barbell",
  "Dumbbell",
  "Cable",
  "Machine",
  "Plate",
  "Bodyweight"
]



trainer_user =
  %User{}
  |> User.registration_changeset(%{
    name: "Sample Trainer",
    email: "trainer@example.com",
    password: "ChangeThisPassword123!",
    role: "trainer"
  })
  |> Repo.insert!()

trainer =
  %Trainer{}
  |> Trainer.changeset(%{
    user_id: trainer_user.id,
    bio: "Experienced fitness trainer specializing in strength training",
    specialization: "Strength & Conditioning"
  })
  |> Repo.insert!()

client_user =
  %User{}
  |> User.registration_changeset(%{
    name: "Alex Client",
    email: "client@example.com",
    password: "ChangeThisPassword123!",
    role: "client"
  })
  |> Repo.insert!()

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

client_user_2 =
  %User{}
  |> User.registration_changeset(%{
    name: "Jane Smith",
    email: "jane@example.com",
    password: "securepassword123",
    role: "client"
  })
  |> Repo.insert!()

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



exercises = [
  %{name: "Deadlift", muscle: "Glutes", equipment: "Barbell"},
  %{name: "Conventional Deadlift", muscle: "Glutes", equipment: "Barbell"},
  %{name: "Hip Thrust", muscle: "Glutes", equipment: "Barbell"},
  %{name: "Cable Pull Through", muscle: "Glutes", equipment: "Cable"},

  %{name: "Wide Lat Pulldown", muscle: "Lats", equipment: "Cable"},
  %{name: "Lat Pulldown", muscle: "Lats", equipment: "Cable"},
  %{name: "Lat Prayer", muscle: "Lats", equipment: "Cable"},
  %{name: "Machine Pullover", muscle: "Lats", equipment: "Machine"},
  %{name: "Dumbbell Pullover", muscle: "Lats", equipment: "Dumbbell"},
  %{name: "Pull Up", muscle: "Lats", equipment: "Bodyweight"},
  %{name: "Chin Up", muscle: "Lats", equipment: "Bodyweight"},

  %{name: "Barbell Bent Over Row", muscle: "Upper Back", equipment: "Barbell"},
  %{name: "Dumbbell Row (One Arm)", muscle: "Upper Back", equipment: "Dumbbell", is_unilateral: true},
  %{name: "Cable Row", muscle: "Upper Back", equipment: "Cable"},
  %{name: "Wide Grip Cable Row", muscle: "Upper Back", equipment: "Cable"},
  %{name: "Seated Row", muscle: "Upper Back", equipment: "Machine"},

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

  %{name: "Romanian Deadlift", muscle: "Hamstrings", equipment: "Barbell"},
  %{name: "Lying Leg Curl", muscle: "Hamstrings", equipment: "Machine"},
  %{name: "Seated Leg Curl", muscle: "Hamstrings", equipment: "Machine"},
  %{name: "Seated Machine Hinge", muscle: "Hamstrings", equipment: "Machine"},
  %{name: "Good Mornings", muscle: "Hamstrings", equipment: "Barbell"},
  %{name: "Single Leg Deadlift", muscle: "Hamstrings", equipment: "Dumbbell", is_unilateral: true},
  %{name: "Back Extension", muscle: "Hamstrings", equipment: "Bodyweight"},

  %{name: "Overhead Press", muscle: "Front Delts", equipment: "Barbell"},
  %{name: "Dumbbell Shoulder Press", muscle: "Front Delts", equipment: "Dumbbell"},
  %{name: "Front Raise", muscle: "Front Delts", equipment: "Dumbbell"},
  %{name: "Arnold Press", muscle: "Front Delts", equipment: "Dumbbell"},

  %{name: "Lateral Raise", muscle: "Side Delts", equipment: "Dumbbell"},
  %{name: "Cable Lateral Raise", muscle: "Side Delts", equipment: "Cable"},
  %{name: "Cable Laterals (One)", muscle: "Side Delts", equipment: "Cable", is_unilateral: true},

  %{name: "Reverse Fly", muscle: "Rear Delts", equipment: "Dumbbell"},
  %{name: "One Arm Reverse Fly", muscle: "Rear Delts", equipment: "Dumbbell", is_unilateral: true},
  %{name: "Face Pull", muscle: "Rear Delts", equipment: "Cable"},

  %{name: "Barbell Bench Press", muscle: "Chest", equipment: "Barbell"},
  %{name: "Incline Barbell Press", muscle: "Chest", equipment: "Barbell"},
  %{name: "Decline Barbell Press", muscle: "Chest", equipment: "Barbell"},
  %{name: "Dumbbell Bench Press", muscle: "Chest", equipment: "Dumbbell"},
  %{name: "Incline Dumbbell Press", muscle: "Chest", equipment: "Dumbbell"},
  %{name: "Decline Dumbbell Press", muscle: "Chest", equipment: "Dumbbell"},
  %{name: "Dumbbell Fly", muscle: "Chest", equipment: "Dumbbell"},
  %{name: "Cable Chest Fly", muscle: "Chest", equipment: "Cable"},
  %{name: "Cable Chest Fly(High To Low)", muscle: "Chest", equipment: "Cable"},
  %{name: "Cable Chest Fly(Low To High)", muscle: "Chest", equipment: "Cable"},
  %{name: "Machine Chest Press", muscle: "Chest", equipment: "Machine"},
  %{name: "Incline Machine Chest Press", muscle: "Chest", equipment: "Machine"},

  %{name: "Barbell Curl", muscle: "Biceps", equipment: "Barbell"},
  %{name: "Preacher Curl", muscle: "Biceps", equipment: "Machine"},
  %{name: "Hammer Curl", muscle: "Biceps", equipment: "Dumbbell"},
  %{name: "Incline Dumbbell Curl", muscle: "Biceps", equipment: "Dumbbell"},
  %{name: "Bayesian Curl", muscle: "Biceps", equipment: "Cable"},
  %{name: "Recline Preacher Curl", muscle: "Biceps", equipment: "Dumbbell"},
  %{name: "Recline Preacher Curl(One Arm)", muscle: "Biceps", equipment: "Dumbbell", is_unilateral: true},

  %{name: "Tricep Pushdown", muscle: "Triceps", equipment: "Cable"},
  %{name: "Tricep Pushdown (One Arm)", muscle: "Triceps", equipment: "Cable", is_unilateral: true},
  %{name: "Tricep Cable Kickback", muscle: "Triceps", equipment: "Cable"},
  %{name: "Skull Crusher", muscle: "Triceps", equipment: "Barbell"},
  %{name: "JM Press", muscle: "Triceps", equipment: "Barbell"},
  %{name: "Close Grip Bench Press", muscle: "Triceps", equipment: "Barbell"},
  %{name: "Bodyweight Dips", muscle: "Triceps", equipment: "Bodyweight"},
  %{name: "Chest Dips", muscle: "Chest", equipment: "Bodyweight"},
  %{name: "Tricep Dips", muscle: "Triceps", equipment: "Bodyweight"},

  %{name: "Standing Calf Raise", muscle: "Calves", equipment: "Machine"},
  %{name: "Seated Calf Raise", muscle: "Calves", equipment: "Machine"},
  %{name: "Leg Press Calf Raise", muscle: "Calves", equipment: "Machine"},

  %{name: "Cable Crunch", muscle: "Abs", equipment: "Cable"},
  %{name: "Plank", muscle: "Abs", equipment: "Bodyweight"},
  %{name: "Leg Raise", muscle: "Abs", equipment: "Bodyweight"},

  %{name: "Hip Adduction Machine", muscle: "Hip Adductors", equipment: "Machine"},
  %{name: "Cable Hip Adduction", muscle: "Hip Adductors", equipment: "Cable", is_unilateral: true},

  %{name: "Hip Abduction Machine", muscle: "Hip Abductors", equipment: "Machine"},
  %{name: "Cable Hip Abduction", muscle: "Hip Abductors", equipment: "Cable", is_unilateral: true},

  %{name: "Wrist Curl", muscle: "Forearms", equipment: "Dumbbell"},
  %{name: "Reverse Wrist Curl", muscle: "Forearms", equipment: "Dumbbell"},
  %{name: "Reverse Barbell Curl", muscle: "Forearms", equipment: "Barbell"},
  %{name: "Farmer's Walk", muscle: "Forearms", equipment: "Dumbbell"},

  %{name: "Barbell Shrug", muscle: "Traps", equipment: "Barbell"},
  %{name: "Dumbbell Shrug", muscle: "Traps", equipment: "Dumbbell"},
  %{name: "Cable Shrug", muscle: "Traps", equipment: "Cable"},

  %{name: "Neck Curl", muscle: "Neck", equipment: "Plate"},
  %{name: "Neck Extension", muscle: "Neck", equipment: "Plate"},
  %{name: "Neck Lateral Flexion", muscle: "Neck", equipment: "Plate", is_unilateral: true},

  %{name: "Hyperextension", muscle: "Lower Back", equipment: "Bodyweight"},
  %{name: "Reverse Hyperextension", muscle: "Lower Back", equipment: "Machine"},
  %{name: "Barbell Good Morning", muscle: "Lower Back", equipment: "Barbell"},

  %{name: "Cable Woodchop", muscle: "Obliques", equipment: "Cable"},
  %{name: "Side Bend", muscle: "Obliques", equipment: "Dumbbell"},
  %{name: "Pallof Press", muscle: "Obliques", equipment: "Cable"}
]

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


contributions = [

  %{exercise: "Barbell Bench Press", muscle: "Chest", role: "primary", multiplier: 1.0},
  %{exercise: "Barbell Bench Press", muscle: "Triceps", role: "secondary", multiplier: 0.5},
  %{exercise: "Barbell Bench Press", muscle: "Front Delts", role: "secondary", multiplier: 0.5},

  %{exercise: "Incline Barbell Press", muscle: "Chest", role: "primary", multiplier: 1.0},
  %{exercise: "Incline Barbell Press", muscle: "Front Delts", role: "secondary", multiplier: 0.5},
  %{exercise: "Incline Barbell Press", muscle: "Triceps", role: "secondary", multiplier: 0.5},

  %{exercise: "Decline Barbell Press", muscle: "Chest", role: "primary", multiplier: 1.0},
  %{exercise: "Decline Barbell Press", muscle: "Triceps", role: "secondary", multiplier: 0.5},
  %{exercise: "Decline Barbell Press", muscle: "Front Delts", role: "secondary", multiplier: 0.5},

  %{exercise: "Dumbbell Bench Press", muscle: "Chest", role: "primary", multiplier: 1.0},
  %{exercise: "Dumbbell Bench Press", muscle: "Triceps", role: "secondary", multiplier: 0.5},
  %{exercise: "Dumbbell Bench Press", muscle: "Front Delts", role: "secondary", multiplier: 0.5},

  %{exercise: "Incline Dumbbell Press", muscle: "Chest", role: "primary", multiplier: 1.0},
  %{exercise: "Incline Dumbbell Press", muscle: "Front Delts", role: "secondary", multiplier: 0.5},
  %{exercise: "Incline Dumbbell Press", muscle: "Triceps", role: "secondary", multiplier: 0.5},

  %{exercise: "Decline Dumbbell Press", muscle: "Chest", role: "primary", multiplier: 1.0},
  %{exercise: "Decline Dumbbell Press", muscle: "Triceps", role: "secondary", multiplier: 0.5},
  %{exercise: "Decline Dumbbell Press", muscle: "Front Delts", role: "secondary", multiplier: 0.5},

  %{exercise: "Dumbbell Fly", muscle: "Chest", role: "primary", multiplier: 1.0},

  %{exercise: "Cable Chest Fly", muscle: "Chest", role: "primary", multiplier: 1.0},
  %{exercise: "Cable Chest Fly(High To Low)", muscle: "Chest", role: "primary", multiplier: 1.0},
  %{exercise: "Cable Chest Fly(Low To High)", muscle: "Chest", role: "primary", multiplier: 1.0},

  %{exercise: "Machine Chest Press", muscle: "Chest", role: "primary", multiplier: 1.0},
  %{exercise: "Machine Chest Press", muscle: "Triceps", role: "secondary", multiplier: 0.5},
  %{exercise: "Machine Chest Press", muscle: "Front Delts", role: "secondary", multiplier: 0.5},

  %{exercise: "Incline Machine Chest Press", muscle: "Chest", role: "primary", multiplier: 1.0},
  %{exercise: "Incline Machine Chest Press", muscle: "Front Delts", role: "secondary", multiplier: 0.5},


  %{exercise: "Deadlift", muscle: "Glutes", role: "primary", multiplier: 1.0},
  %{exercise: "Deadlift", muscle: "Hamstrings", role: "secondary", multiplier: 0.5},
  %{exercise: "Deadlift", muscle: "Lats", role: "secondary", multiplier: 0.5},
  %{exercise: "Deadlift", muscle: "Lower Back", role: "secondary", multiplier: 0.5},
  %{exercise: "Deadlift", muscle: "Traps", role: "secondary", multiplier: 0.5},
  %{exercise: "Deadlift", muscle: "Forearms", role: "secondary", multiplier: 0.5},

  %{exercise: "Conventional Deadlift", muscle: "Glutes", role: "primary", multiplier: 1.0},
  %{exercise: "Conventional Deadlift", muscle: "Hamstrings", role: "secondary", multiplier: 0.5},
  %{exercise: "Conventional Deadlift", muscle: "Lats", role: "secondary", multiplier: 0.5},
  %{exercise: "Conventional Deadlift", muscle: "Lower Back", role: "secondary", multiplier: 0.5},
  %{exercise: "Conventional Deadlift", muscle: "Traps", role: "secondary", multiplier: 0.5},
  %{exercise: "Conventional Deadlift", muscle: "Forearms", role: "secondary", multiplier: 0.5},

  %{exercise: "Hip Thrust", muscle: "Glutes", role: "primary", multiplier: 1.0},
  %{exercise: "Hip Thrust", muscle: "Hamstrings", role: "secondary", multiplier: 0.5},

  %{exercise: "Cable Pull Through", muscle: "Glutes", role: "primary", multiplier: 1.0},
  %{exercise: "Cable Pull Through", muscle: "Hamstrings", role: "secondary", multiplier: 0.5},


  %{exercise: "Wide Lat Pulldown", muscle: "Lats", role: "primary", multiplier: 1.0},
  %{exercise: "Wide Lat Pulldown", muscle: "Biceps", role: "secondary", multiplier: 0.5},
  %{exercise: "Wide Lat Pulldown", muscle: "Rear Delts", role: "secondary", multiplier: 0.5},

  %{exercise: "Lat Pulldown", muscle: "Lats", role: "primary", multiplier: 1.0},
  %{exercise: "Lat Pulldown", muscle: "Biceps", role: "secondary", multiplier: 0.5},
  %{exercise: "Lat Pulldown", muscle: "Rear Delts", role: "secondary", multiplier: 0.5},

  %{exercise: "Machine Pullover", muscle: "Lats", role: "primary", multiplier: 1.0},

  %{exercise: "Dumbbell Pullover", muscle: "Lats", role: "primary", multiplier: 1.0},

  %{exercise: "Pull Up", muscle: "Lats", role: "primary", multiplier: 1.0},
  %{exercise: "Pull Up", muscle: "Biceps", role: "secondary", multiplier: 0.5},
  %{exercise: "Pull Up", muscle: "Rear Delts", role: "secondary", multiplier: 0.5},

  %{exercise: "Chin Up", muscle: "Lats", role: "primary", multiplier: 1.0},
  %{exercise: "Chin Up", muscle: "Biceps", role: "secondary", multiplier: 0.5},
  %{exercise: "Chin Up", muscle: "Rear Delts", role: "secondary", multiplier: 0.5},

  %{exercise: "Lat Prayer", muscle: "Lats", role: "primary", multiplier: 1.0},


  %{exercise: "Barbell Bent Over Row", muscle: "Upper Back", role: "primary", multiplier: 1.0},
  %{exercise: "Barbell Bent Over Row", muscle: "Lats", role: "secondary", multiplier: 0.5},
  %{exercise: "Barbell Bent Over Row", muscle: "Biceps", role: "secondary", multiplier: 0.5},
  %{exercise: "Barbell Bent Over Row", muscle: "Rear Delts", role: "secondary", multiplier: 0.5},
  %{exercise: "Barbell Bent Over Row", muscle: "Forearms", role: "secondary", multiplier: 0.5},

  %{exercise: "Dumbbell Row (One Arm)", muscle: "Upper Back", role: "primary", multiplier: 1.0},
  %{exercise: "Dumbbell Row (One Arm)", muscle: "Lats", role: "secondary", multiplier: 0.5},
  %{exercise: "Dumbbell Row (One Arm)", muscle: "Biceps", role: "secondary", multiplier: 0.5},
  %{exercise: "Dumbbell Row (One Arm)", muscle: "Rear Delts", role: "secondary", multiplier: 0.5},

  %{exercise: "Cable Row", muscle: "Upper Back", role: "primary", multiplier: 1.0},
  %{exercise: "Cable Row", muscle: "Lats", role: "secondary", multiplier: 0.5},
  %{exercise: "Cable Row", muscle: "Biceps", role: "secondary", multiplier: 0.5},
  %{exercise: "Cable Row", muscle: "Rear Delts", role: "secondary", multiplier: 0.5},

  %{exercise: "Wide Grip Cable Row", muscle: "Upper Back", role: "primary", multiplier: 1.0},
  %{exercise: "Wide Grip Cable Row", muscle: "Rear Delts", role: "secondary", multiplier: 0.5},
  %{exercise: "Wide Grip Cable Row", muscle: "Biceps", role: "secondary", multiplier: 0.5},

  %{exercise: "Seated Row", muscle: "Upper Back", role: "primary", multiplier: 1.0},
  %{exercise: "Seated Row", muscle: "Lats", role: "secondary", multiplier: 0.5},
  %{exercise: "Seated Row", muscle: "Biceps", role: "secondary", multiplier: 0.5},
  %{exercise: "Seated Row", muscle: "Rear Delts", role: "secondary", multiplier: 0.5},


  %{exercise: "Barbell Squat", muscle: "Quads", role: "primary", multiplier: 1.0},
  %{exercise: "Barbell Squat", muscle: "Glutes", role: "secondary", multiplier: 0.5},
  %{exercise: "Barbell Squat", muscle: "Lower Back", role: "secondary", multiplier: 0.5},

  %{exercise: "Front Squat", muscle: "Quads", role: "primary", multiplier: 1.0},

  %{exercise: "Leg Press", muscle: "Quads", role: "primary", multiplier: 1.0},
  %{exercise: "Leg Press", muscle: "Glutes", role: "secondary", multiplier: 0.5},

  %{exercise: "Hack Squat", muscle: "Quads", role: "primary", multiplier: 1.0},
  %{exercise: "Hack Squat", muscle: "Glutes", role: "secondary", multiplier: 0.5},

  %{exercise: "Leg Extension", muscle: "Quads", role: "primary", multiplier: 1.0},

  %{exercise: "Bulgarian Split Squat", muscle: "Quads", role: "primary", multiplier: 1.0},
  %{exercise: "Bulgarian Split Squat", muscle: "Glutes", role: "secondary", multiplier: 0.5},

  %{exercise: "Lunges", muscle: "Quads", role: "primary", multiplier: 1.0},
  %{exercise: "Lunges", muscle: "Glutes", role: "secondary", multiplier: 0.5},

  %{exercise: "Single Leg Extension", muscle: "Quads", role: "primary", multiplier: 1.0},

  %{exercise: "Reverse Lunges", muscle: "Quads", role: "primary", multiplier: 1.0},
  %{exercise: "Reverse Lunges", muscle: "Glutes", role: "secondary", multiplier: 0.5},

  %{exercise: "Sissy Squat", muscle: "Quads", role: "primary", multiplier: 1.0},


  %{exercise: "Romanian Deadlift", muscle: "Hamstrings", role: "primary", multiplier: 1.0},
  %{exercise: "Romanian Deadlift", muscle: "Glutes", role: "secondary", multiplier: 0.5},
  %{exercise: "Romanian Deadlift", muscle: "Lower Back", role: "secondary", multiplier: 0.5},
  %{exercise: "Romanian Deadlift", muscle: "Forearms", role: "secondary", multiplier: 0.5},

  %{exercise: "Lying Leg Curl", muscle: "Hamstrings", role: "primary", multiplier: 1.0},

  %{exercise: "Seated Leg Curl", muscle: "Hamstrings", role: "primary", multiplier: 1.0},

  %{exercise: "Seated Machine Hinge", muscle: "Hamstrings", role: "primary", multiplier: 1.0},
  %{exercise: "Seated Machine Hinge", muscle: "Glutes", role: "secondary", multiplier: 0.5},

  %{exercise: "Good Mornings", muscle: "Hamstrings", role: "primary", multiplier: 1.0},
  %{exercise: "Good Mornings", muscle: "Glutes", role: "secondary", multiplier: 0.5},
  %{exercise: "Good Mornings", muscle: "Lower Back", role: "secondary", multiplier: 0.5},

  %{exercise: "Single Leg Deadlift", muscle: "Hamstrings", role: "primary", multiplier: 1.0},
  %{exercise: "Single Leg Deadlift", muscle: "Glutes", role: "secondary", multiplier: 0.5},

  %{exercise: "Back Extension", muscle: "Hamstrings", role: "primary", multiplier: 1.0},
  %{exercise: "Back Extension", muscle: "Glutes", role: "secondary", multiplier: 0.5},
  %{exercise: "Back Extension", muscle: "Lower Back", role: "secondary", multiplier: 0.5},


  %{exercise: "Overhead Press", muscle: "Front Delts", role: "primary", multiplier: 1.0},
  %{exercise: "Overhead Press", muscle: "Triceps", role: "secondary", multiplier: 0.5},
  %{exercise: "Overhead Press", muscle: "Traps", role: "secondary", multiplier: 0.5},

  %{exercise: "Dumbbell Shoulder Press", muscle: "Front Delts", role: "primary", multiplier: 1.0},
  %{exercise: "Dumbbell Shoulder Press", muscle: "Triceps", role: "secondary", multiplier: 0.5},
  %{exercise: "Dumbbell Shoulder Press", muscle: "Traps", role: "secondary", multiplier: 0.5},

  %{exercise: "Front Raise", muscle: "Front Delts", role: "primary", multiplier: 1.0},

  %{exercise: "Arnold Press", muscle: "Front Delts", role: "primary", multiplier: 1.0},
  %{exercise: "Arnold Press", muscle: "Side Delts", role: "secondary", multiplier: 0.5},
  %{exercise: "Arnold Press", muscle: "Triceps", role: "secondary", multiplier: 0.5},


  %{exercise: "Lateral Raise", muscle: "Side Delts", role: "primary", multiplier: 1.0},

  %{exercise: "Cable Lateral Raise", muscle: "Side Delts", role: "primary", multiplier: 1.0},

  %{exercise: "Cable Laterals (One)", muscle: "Side Delts", role: "primary", multiplier: 1.0},


  %{exercise: "Reverse Fly", muscle: "Rear Delts", role: "primary", multiplier: 1.0},
  %{exercise: "Reverse Fly", muscle: "Upper Back", role: "secondary", multiplier: 0.5},

  %{exercise: "One Arm Reverse Fly", muscle: "Rear Delts", role: "primary", multiplier: 1.0},
  %{exercise: "One Arm Reverse Fly", muscle: "Upper Back", role: "secondary", multiplier: 0.5},

  %{exercise: "Face Pull", muscle: "Rear Delts", role: "primary", multiplier: 1.0},
  %{exercise: "Face Pull", muscle: "Upper Back", role: "secondary", multiplier: 0.5},


  %{exercise: "Barbell Curl", muscle: "Biceps", role: "primary", multiplier: 1.0},
  %{exercise: "Preacher Curl", muscle: "Biceps", role: "primary", multiplier: 1.0},
  %{exercise: "Hammer Curl", muscle: "Biceps", role: "primary", multiplier: 1.0},
  %{exercise: "Hammer Curl", muscle: "Forearms", role: "secondary", multiplier: 0.5},
  %{exercise: "Incline Dumbbell Curl", muscle: "Biceps", role: "primary", multiplier: 1.0},
  %{exercise: "Bayesian Curl", muscle: "Biceps", role: "primary", multiplier: 1.0},
  %{exercise: "Recline Preacher Curl", muscle: "Biceps", role: "primary", multiplier: 1.0},
  %{exercise: "Recline Preacher Curl(One Arm)", muscle: "Biceps", role: "primary", multiplier: 1.0},


  %{exercise: "Tricep Pushdown", muscle: "Triceps", role: "primary", multiplier: 1.0},
  %{exercise: "Tricep Pushdown (One Arm)", muscle: "Triceps", role: "primary", multiplier: 1.0},
  %{exercise: "Tricep Cable Kickback", muscle: "Triceps", role: "primary", multiplier: 1.0},
  %{exercise: "Skull Crusher", muscle: "Triceps", role: "primary", multiplier: 1.0},
  %{exercise: "JM Press", muscle: "Triceps", role: "primary", multiplier: 1.0},

  %{exercise: "Close Grip Bench Press", muscle: "Triceps", role: "primary", multiplier: 1.0},
  %{exercise: "Close Grip Bench Press", muscle: "Chest", role: "secondary", multiplier: 0.5},
  %{exercise: "Close Grip Bench Press", muscle: "Front Delts", role: "secondary", multiplier: 0.5},

  %{exercise: "Bodyweight Dips", muscle: "Triceps", role: "primary", multiplier: 1.0},
  %{exercise: "Bodyweight Dips", muscle: "Chest", role: "secondary", multiplier: 0.5},
  %{exercise: "Bodyweight Dips", muscle: "Front Delts", role: "secondary", multiplier: 0.5},

  %{exercise: "Chest Dips", muscle: "Chest", role: "primary", multiplier: 1.0},
  %{exercise: "Chest Dips", muscle: "Triceps", role: "secondary", multiplier: 0.5},
  %{exercise: "Chest Dips", muscle: "Front Delts", role: "secondary", multiplier: 0.5},

  %{exercise: "Tricep Dips", muscle: "Triceps", role: "primary", multiplier: 1.0},
  %{exercise: "Tricep Dips", muscle: "Chest", role: "secondary", multiplier: 0.3},
  %{exercise: "Tricep Dips", muscle: "Front Delts", role: "secondary", multiplier: 0.5},


  %{exercise: "Standing Calf Raise", muscle: "Calves", role: "primary", multiplier: 1.0},
  %{exercise: "Seated Calf Raise", muscle: "Calves", role: "primary", multiplier: 1.0},
  %{exercise: "Leg Press Calf Raise", muscle: "Calves", role: "primary", multiplier: 1.0},


  %{exercise: "Cable Crunch", muscle: "Abs", role: "primary", multiplier: 1.0},
  %{exercise: "Plank", muscle: "Abs", role: "primary", multiplier: 1.0},
  %{exercise: "Leg Raise", muscle: "Abs", role: "primary", multiplier: 1.0},


  %{exercise: "Hip Adduction Machine", muscle: "Hip Adductors", role: "primary", multiplier: 1.0},
  %{exercise: "Cable Hip Adduction", muscle: "Hip Adductors", role: "primary", multiplier: 1.0},


  %{exercise: "Hip Abduction Machine", muscle: "Hip Abductors", role: "primary", multiplier: 1.0},
  %{exercise: "Cable Hip Abduction", muscle: "Hip Abductors", role: "primary", multiplier: 1.0},


  %{exercise: "Wrist Curl", muscle: "Forearms", role: "primary", multiplier: 1.0},

  %{exercise: "Reverse Wrist Curl", muscle: "Forearms", role: "primary", multiplier: 1.0},

  %{exercise: "Reverse Barbell Curl", muscle: "Forearms", role: "primary", multiplier: 1.0},
  %{exercise: "Reverse Barbell Curl", muscle: "Biceps", role: "secondary", multiplier: 0.5},

  %{exercise: "Farmer's Walk", muscle: "Forearms", role: "primary", multiplier: 1.0},
  %{exercise: "Farmer's Walk", muscle: "Traps", role: "secondary", multiplier: 0.5},


  %{exercise: "Barbell Shrug", muscle: "Traps", role: "primary", multiplier: 1.0},

  %{exercise: "Dumbbell Shrug", muscle: "Traps", role: "primary", multiplier: 1.0},

  %{exercise: "Cable Shrug", muscle: "Traps", role: "primary", multiplier: 1.0},


  %{exercise: "Neck Curl", muscle: "Neck", role: "primary", multiplier: 1.0},
  %{exercise: "Neck Extension", muscle: "Neck", role: "primary", multiplier: 1.0},
  %{exercise: "Neck Lateral Flexion", muscle: "Neck", role: "primary", multiplier: 1.0},


  %{exercise: "Hyperextension", muscle: "Lower Back", role: "primary", multiplier: 1.0},
  %{exercise: "Hyperextension", muscle: "Glutes", role: "secondary", multiplier: 0.5},

  %{exercise: "Reverse Hyperextension", muscle: "Lower Back", role: "primary", multiplier: 1.0},
  %{exercise: "Reverse Hyperextension", muscle: "Glutes", role: "secondary", multiplier: 0.5},

  %{exercise: "Barbell Good Morning", muscle: "Lower Back", role: "primary", multiplier: 1.0},
  %{exercise: "Barbell Good Morning", muscle: "Hamstrings", role: "secondary", multiplier: 0.5},


  %{exercise: "Cable Woodchop", muscle: "Obliques", role: "primary", multiplier: 1.0},
  %{exercise: "Cable Woodchop", muscle: "Abs", role: "secondary", multiplier: 0.5},

  %{exercise: "Side Bend", muscle: "Obliques", role: "primary", multiplier: 1.0},

  %{exercise: "Pallof Press", muscle: "Obliques", role: "primary", multiplier: 1.0},
  %{exercise: "Pallof Press", muscle: "Abs", role: "secondary", multiplier: 0.5}
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
