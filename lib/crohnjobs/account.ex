defmodule Crohnjobs.Account do
  @moduledoc """
  The Account context.
  """

  import Ecto.Query, warn: false
  alias Crohnjobs.Repo

  alias Crohnjobs.Account.{User, UserToken, UserNotifier}

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end


  @doc """
  Generates a demo trainer account with sample clients, programmes, and workouts.
  Returns {:ok, user} or {:error, reason}.
  """
  def generate_demo_account do
    alias Crohnjobs.{Trainers, Clients, Subscriptions, Programmes, Training}
    alias Crohnjobs.Exercises.Exercise

    random = :crypto.strong_rand_bytes(5) |> Base.encode32(case: :lower, padding: false)
    email = "demo_#{random}@scopestrength.com"
    password = :crypto.strong_rand_bytes(12) |> Base.encode64()

    Repo.transaction(fn ->
      # 1. Create trainer user
      {:ok, trainer_user} =
        register_user(%{
          name: "Demo Trainer",
          email: email,
          password: password,
          role: "trainer"
        })

      # 2. Create trainer profile
      {:ok, trainer} =
        Trainers.create_trainer(%{
          user_id: trainer_user.id,
          bio: "Demo account — explore all features!",
          specialization: "General Fitness"
        })

      # 3. Create 3-day demo trial subscription
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      {:ok, _sub} =
        Subscriptions.create_subscription(%{
          user_id: trainer_user.id,
          name: "Demo Trial",
          plan: "trial",
          trial_start: now,
          trial_end: DateTime.add(now, 3 * 86_400, :second)
        })

      # 4. Create 3 demo clients
      clients_data = [
        %{name: "Alex Johnson", age: 28, sex: "male", height: "178.0", notes: "Intermediate lifter, focuses on strength"},
        %{name: "Sarah Martinez", age: 32, sex: "female", height: "165.0", notes: "Experienced, training for hypertrophy"},
        %{name: "Mike Chen", age: 25, sex: "male", height: "182.0", notes: "Beginner, building base strength"}
      ]

      clients =
        Enum.map(clients_data, fn data ->
          client_random = :crypto.strong_rand_bytes(5) |> Base.encode32(case: :lower, padding: false)

          {:ok, client_user} =
            register_user(%{
              name: data.name,
              email: "demo_client_#{client_random}@scopestrength.com",
              password: password,
              role: "client"
            })

          {:ok, client} =
            Clients.create_client(%{
              user_id: client_user.id,
              trainer_id: trainer.id,
              age: data.age,
              sex: data.sex,
              height: data.height,
              active: true,
              notes: data.notes
            })

          client
        end)

      [alex, sarah, mike] = clients

      # 5. Lookup exercises by name (from seed data)
      exercise_names = [
        "Barbell Bench Press", "Incline Dumbbell Press", "Cable Chest Fly",
        "Tricep Pushdown", "Lateral Raise",
        "Barbell Bent Over Row", "Lat Pulldown", "Cable Row",
        "Barbell Curl", "Face Pull",
        "Barbell Squat", "Romanian Deadlift", "Leg Press",
        "Leg Extension", "Lying Leg Curl",
        "Overhead Press", "Dumbbell Shoulder Press",
        "Dumbbell Bench Press", "Cable Lateral Raise"
      ]

      exercises =
        Enum.into(exercise_names, %{}, fn name ->
          case Repo.get_by(Exercise, name: name) do
            nil -> {name, nil}
            ex -> {name, ex.id}
          end
        end)

      # 6. Create programmes with templates and details
      # Programme 1: Push Pull Legs
      {:ok, ppl} = Programmes.create_programme(%{name: "Push Pull Legs", description: "Classic 3-day split", trainer_id: trainer.id})

      {:ok, push_day} = Programmes.create_programme_template(%{name: "Push Day", programme_id: ppl.id})
      for {ex_name, sets, reps, rir} <- [
        {"Barbell Bench Press", "4", "8", 2},
        {"Incline Dumbbell Press", "3", "10", 2},
        {"Cable Chest Fly", "3", "12", 1},
        {"Overhead Press", "3", "8", 2},
        {"Lateral Raise", "3", "15", 1},
        {"Tricep Pushdown", "3", "12", 1}
      ], exercises[ex_name] do
        Programmes.create_programme_details(%{
          programme_template_id: push_day.id,
          exercise_id: exercises[ex_name],
          set: sets, reps: reps, rir: rir
        })
      end

      {:ok, pull_day} = Programmes.create_programme_template(%{name: "Pull Day", programme_id: ppl.id})
      for {ex_name, sets, reps, rir} <- [
        {"Barbell Bent Over Row", "4", "8", 2},
        {"Lat Pulldown", "3", "10", 2},
        {"Cable Row", "3", "10", 2},
        {"Face Pull", "3", "15", 1},
        {"Barbell Curl", "3", "10", 1}
      ], exercises[ex_name] do
        Programmes.create_programme_details(%{
          programme_template_id: pull_day.id,
          exercise_id: exercises[ex_name],
          set: sets, reps: reps, rir: rir
        })
      end

      {:ok, leg_day} = Programmes.create_programme_template(%{name: "Leg Day", programme_id: ppl.id})
      for {ex_name, sets, reps, rir} <- [
        {"Barbell Squat", "4", "6", 2},
        {"Romanian Deadlift", "3", "8", 2},
        {"Leg Press", "3", "10", 2},
        {"Leg Extension", "3", "12", 1},
        {"Lying Leg Curl", "3", "12", 1}
      ], exercises[ex_name] do
        Programmes.create_programme_details(%{
          programme_template_id: leg_day.id,
          exercise_id: exercises[ex_name],
          set: sets, reps: reps, rir: rir
        })
      end

      # Programme 2: Upper Lower
      {:ok, ul} = Programmes.create_programme(%{name: "Upper Lower", description: "4-day upper/lower split", trainer_id: trainer.id})

      {:ok, upper} = Programmes.create_programme_template(%{name: "Upper Body", programme_id: ul.id})
      for {ex_name, sets, reps, rir} <- [
        {"Dumbbell Bench Press", "4", "8", 2},
        {"Cable Row", "4", "10", 2},
        {"Dumbbell Shoulder Press", "3", "10", 2},
        {"Cable Lateral Raise", "3", "15", 1},
        {"Barbell Curl", "3", "10", 1},
        {"Tricep Pushdown", "3", "12", 1}
      ], exercises[ex_name] do
        Programmes.create_programme_details(%{
          programme_template_id: upper.id,
          exercise_id: exercises[ex_name],
          set: sets, reps: reps, rir: rir
        })
      end

      {:ok, lower} = Programmes.create_programme_template(%{name: "Lower Body", programme_id: ul.id})
      for {ex_name, sets, reps, rir} <- [
        {"Barbell Squat", "4", "6", 2},
        {"Romanian Deadlift", "3", "8", 2},
        {"Leg Press", "3", "10", 2},
        {"Leg Extension", "3", "12", 1},
        {"Lying Leg Curl", "3", "12", 1}
      ], exercises[ex_name] do
        Programmes.create_programme_details(%{
          programme_template_id: lower.id,
          exercise_id: exercises[ex_name],
          set: sets, reps: reps, rir: rir
        })
      end

      # 7. Assign programmes to clients
      Programmes.create_programme_user(%{programme_id: ppl.id, client_id: alex.id, is_active: true})
      Programmes.create_programme_user(%{programme_id: ul.id, client_id: sarah.id, is_active: true})
      Programmes.create_programme_user(%{programme_id: ppl.id, client_id: mike.id, is_active: true})

      # 8. Create sample workouts
      standard_set_type = Repo.get_by(Training.SetType, name: "Standard")
      set_type_id = if standard_set_type, do: standard_set_type.id

      # Workout 1: Alex's Push Day (2 days ago)
      {:ok, w1} = Training.create_workout(%{
        name: "Push Day - Week 1",
        date: DateTime.add(now, -2 * 86_400, :second),
        notes: "Felt strong today",
        client_id: alex.id
      })

      for {ex_name, sets_data} <- [
        {"Barbell Bench Press", [{1, 10, 60.0}, {2, 8, 70.0}, {3, 8, 70.0}, {4, 6, 75.0}]},
        {"Incline Dumbbell Press", [{1, 10, 22.5}, {2, 10, 22.5}, {3, 8, 25.0}]},
        {"Lateral Raise", [{1, 15, 8.0}, {2, 12, 8.0}, {3, 12, 8.0}]}
      ], exercises[ex_name] do
        for {set_num, reps, weight} <- sets_data do
          Training.create_workout_details(%{
            workout_id: w1.id, exercise_id: exercises[ex_name],
            set: set_num, reps: reps, weight: weight, set_type_id: set_type_id
          })
        end
      end

      # Workout 2: Sarah's Upper Body (yesterday)
      {:ok, w2} = Training.create_workout(%{
        name: "Upper Body - Week 1",
        date: DateTime.add(now, -86_400, :second),
        notes: "Good session, increased weight on rows",
        client_id: sarah.id
      })

      for {ex_name, sets_data} <- [
        {"Dumbbell Bench Press", [{1, 10, 16.0}, {2, 10, 16.0}, {3, 8, 18.0}, {4, 8, 18.0}]},
        {"Cable Row", [{1, 12, 30.0}, {2, 10, 35.0}, {3, 10, 35.0}]},
        {"Barbell Curl", [{1, 12, 15.0}, {2, 10, 15.0}, {3, 10, 15.0}]}
      ], exercises[ex_name] do
        for {set_num, reps, weight} <- sets_data do
          Training.create_workout_details(%{
            workout_id: w2.id, exercise_id: exercises[ex_name],
            set: set_num, reps: reps, weight: weight, set_type_id: set_type_id
          })
        end
      end

      # Workout 3: Mike's Leg Day (today)
      {:ok, w3} = Training.create_workout(%{
        name: "Leg Day - Week 1",
        date: now,
        notes: "First leg day, took it easy",
        client_id: mike.id
      })

      for {ex_name, sets_data} <- [
        {"Barbell Squat", [{1, 10, 40.0}, {2, 8, 50.0}, {3, 8, 50.0}, {4, 6, 55.0}]},
        {"Leg Press", [{1, 12, 80.0}, {2, 10, 100.0}, {3, 10, 100.0}]},
        {"Leg Extension", [{1, 12, 25.0}, {2, 12, 25.0}, {3, 10, 30.0}]}
      ], exercises[ex_name] do
        for {set_num, reps, weight} <- sets_data do
          Training.create_workout_details(%{
            workout_id: w3.id, exercise_id: exercises[ex_name],
            set: set_num, reps: reps, weight: weight, set_type_id: set_type_id
          })
        end
      end

      trainer_user
    end)
  end


  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false, validate_email: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}) do
    User.email_changeset(user, attrs, validate_email: false)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_user_email(user, "valid password", %{email: ...})
      {:ok, %User{}}

      iex> apply_user_email(user, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_user_email(user, password, attrs) do
    user
    |> User.email_changeset(attrs)
    |> User.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
         %UserToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(user_email_multi(user, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp user_email_multi(user, email, context) do
    changeset =
      user
      |> User.email_changeset(%{email: email})
      |> User.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, [context]))
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(user, current_email, &url(~p"/users/settings/confirm_email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  @doc """
  Updates the user password.

  ## Examples

      iex> update_user_password(user, "valid password", %{password: ...})
      {:ok, %User{}}

      iex> update_user_password(user, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.by_token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc ~S"""
  Delivers the confirmation email instructions to the given user.

  ## Examples

      iex> deliver_user_confirmation_instructions(user, &url(~p"/users/confirm/#{&1}"))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_user_confirmation_instructions(confirmed_user, &url(~p"/users/confirm/#{&1}"))
      {:error, :already_confirmed}

  """
  def deliver_user_confirmation_instructions(%User{} = user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
      Repo.insert!(user_token)
      UserNotifier.deliver_confirmation_instructions(user, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a user by the given token.

  If the token matches, the user account is marked as confirmed
  and the token is deleted.
  """
  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, %{user: user}} <- Repo.transaction(confirm_user_multi(user)) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  defp confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, ["confirm"]))
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given user.

  ## Examples

      iex> deliver_user_reset_password_instructions(user, &url(~p"/users/reset_password/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    UserNotifier.deliver_reset_password_instructions(user, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the user by reset password token.

  ## Examples

      iex> get_user_by_reset_password_token("validtoken")
      %User{}

      iex> get_user_by_reset_password_token("invalidtoken")
      nil




  """

  def update_name(%User{}= user, attrs) do
    user|> Ecto.Changeset.cast(attrs, [:name])
    |> Repo.update()
  end

  def update_role(%User{}= user,attrs) do
    user|>Ecto.Changeset.cast(attrs,[:role])|>Repo.update()
  end


  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Resets the user password.

  ## Examples

      iex> reset_user_password(user, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %User{}}

      iex> reset_user_password(user, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_user_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end
end
