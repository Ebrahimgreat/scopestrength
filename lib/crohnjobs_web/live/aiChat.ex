defmodule CrohnjobsWeb.AiChat do
alias Crohnjobs.Account.User
  use CrohnjobsWeb, :live_view
  alias Crohnjobs.Trainers
  alias Crohnjobs.Clients
  alias Crohnjobs.Repo

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    context = build_user_context(user)

    {:ok,
     socket
     |> assign(:user, user)
     |> assign(:messages, [])
     |> assign(:text, "")
     |> assign(:loading, false)
     |> assign(:context, context)
     |> assign(:conversation_state, %{})}
  end

  def handle_event("send", %{"text" => text}, socket) when text != "" do
    user_message = %{role: :user, content: text, timestamp: DateTime.utc_now()}
    messages = socket.assigns.messages ++ [user_message]

    # Build conversation history for Gemini
    context = Enum.map(messages, fn msg ->
      %{role: msg.role, content: msg.content}
    end)

    # Add system context at the beginning
    full_context = [socket.assigns.context | context]

    {:noreply,
     socket
     |> assign(:messages, messages)
     |> assign(:text, "")
     |> assign(:loading, true)
     |> start_async(:chat, fn -> send_to_gemini(text, full_context) end)}
  end

  def handle_event("send", _params, socket) do
    {:noreply, socket}
  end

  def handle_async(:chat, {:ok, {:ok, response}}, socket) do
    # Check if response contains workout creation command
    {final_response, socket} = process_ai_response(response, socket)

    bot_message = %{role: :assistant, content: final_response, timestamp: DateTime.utc_now()}
    messages = socket.assigns.messages ++ [bot_message]

    {:noreply,
     socket
     |> assign(:messages, messages)
     |> assign(:loading, false)}
  end

  def handle_async(:chat, {:ok, {:error, error}}, socket) do
    bot_message = %{
      role: :assistant,
      content: "I'm having trouble right now: #{error}",
      timestamp: DateTime.utc_now()
    }
    messages = socket.assigns.messages ++ [bot_message]

    {:noreply,
     socket
     |> assign(:messages, messages)
     |> assign(:loading, false)}
  end

  defp send_to_gemini(text, context) do
    Crohnjobs.AI.Gemini.chat(text, context)
  end

  defp process_ai_response(response, socket) do
    # Check if the AI response contains a workout creation command
    # Format: [CREATE_WORKOUT]name|date|exercise1:sets:reps:weight,exercise2:sets:reps:weight[/CREATE_WORKOUT]
    case Regex.run(~r/\[CREATE_WORKOUT\](.*?)\[\/CREATE_WORKOUT\]/s, response) do
      [full_match, workout_data] ->
        # Parse and create the workout
        result = parse_and_create_workout(workout_data, socket)

        # Remove the command from the response and add the result message
        cleaned_response = String.replace(response, full_match, "")
        final_response = String.trim(cleaned_response) <> "\n\n" <> result.message

        {final_response, socket}

      nil ->
        # No workout creation command, return response as-is
        {response, socket}
    end
  end

  defp parse_and_create_workout(workout_data, socket) do
    user = socket.assigns.user

    # Only clients can create workouts for themselves
    if user.role != "client" do
      %{success: false, message: "❌ Only clients can track workouts."}
    else
      client = Repo.get_by(Clients.Client, user_id: user.id)

      if !client do
        %{success: false, message: "❌ Client not found."}
      else
        try do
          # Parse: name|date|exercise1:sets:reps:weight,exercise2:sets:reps:weight
          parts = String.split(workout_data, "|", parts: 3)

          case parts do
            [name, date_str, exercises_str] ->
              # Parse date (could be "today", "yesterday", or ISO date)
              workout_date = parse_workout_date(date_str)

              # Create the workout
              {:ok, workout} = Crohnjobs.Training.create_workout(%{
                client_id: client.id,
                name: String.trim(name),
                date: workout_date
              })

              # Parse and create exercises
              exercises_str
              |> String.split(",")
              |> Enum.each(fn exercise_str ->
                case String.split(exercise_str, ":") do
                  [exercise_name, sets, reps, weight] ->
                    # Find exercise by name
                    exercise = Repo.get_by(Crohnjobs.Exercises.Exercise, name: String.trim(exercise_name))

                    if exercise do
                      # Create sets
                      sets_count = String.to_integer(String.trim(sets))
                      reps_val = String.to_float(String.trim(reps))
                      weight_val = String.to_float(String.trim(weight))

                      for set_num <- 1..sets_count do
                        Crohnjobs.Training.create_workout_details(%{
                          workout_id: workout.id,
                          exercise_id: exercise.id,
                          set: set_num,
                          reps: reps_val,
                          weight: weight_val
                        })
                      end
                    end

                  _ -> :ok
                end
              end)

              %{success: true, message: "✅ Workout '#{name}' created successfully! You can view it in your workouts page."}

            _ ->
              %{success: false, message: "❌ Invalid workout format."}
          end
        rescue
          _ ->
            %{success: false, message: "❌ Error creating workout. Please try again."}
        end
      end
    end
  end

  defp parse_workout_date(date_str) do
    date_str = String.trim(String.downcase(date_str))

    case date_str do
      "today" -> DateTime.utc_now()
      "yesterday" -> DateTime.utc_now() |> DateTime.add(-1, :day)
      _ ->
        # Try to parse as ISO date
        case DateTime.from_iso8601(date_str) do
          {:ok, datetime, _} -> datetime
          _ -> DateTime.utc_now()
        end
    end
  end

  defp build_user_context(user) do
    case user.role do
      "trainer" ->
        trainer = Trainers.get_trainer_byUserId(user.id)
        client_stats = get_trainer_client_stats(trainer.id)

        %{
          role: :system,
          content: """
          You are an AI fitness assistant in a workout tracking app called Scope Application.

          IMPORTANT CONTEXT:
          - You are chatting with a TRAINER named "#{user.name || "Unknown"}"
          - Trainer ID: #{trainer.id}
          - When they ask "who am I?" or "what's my name?", tell them: "You are #{user.name}, a trainer"
          - When they ask "what's my role?", tell them: "You are a trainer"

          TRAINER'S CURRENT STATS:
          - Total clients: #{client_stats.total_clients}
          - Active clients (with workouts in last 7 days): #{client_stats.active_clients}
          - When they ask "how many clients do I have?" or similar, tell them: "You have #{client_stats.total_clients} total clients, with #{client_stats.active_clients} active in the last 7 days"

          YOUR CAPABILITIES FOR TRAINERS:
          1. Answer questions about training methodologies, program design, and exercise science
          2. Provide coaching advice and client management strategies
          3. Discuss periodization, progressive overload, and training principles
          4. Help with exercise selection and program planning
          5. Offer guidance on client communication and motivation techniques

          RESPONSE STYLE FOR TRAINERS:
          - Use professional fitness terminology
          - Focus on evidence-based approaches
          - Provide actionable coaching insights
          - Be direct and efficient with information
          - Reference training principles and methodologies when relevant

          LIMITATIONS:
          - You cannot access or modify their clients' data
          - You cannot create or edit workout programs in the system
          - You cannot view specific client information
          - You provide guidance and information only

          Keep responses concise and professional. Address them as a fellow fitness professional.
          """
        }

      "client" ->
        client = Repo.get_by(Clients.Client,%{user_id: user.id})
        trainer_info = if client && client.trainer_id do
          trainer = Trainers.get_trainer!(client.trainer_id)
          if trainer do
            trainer_user = Repo.get_by(User,%{id: trainer.user_id})
            %{name: trainer_user.name, id: trainer.id}
          else
            nil
          end
        else
          nil
        end

        workout_stats = if client, do: get_client_workout_stats(client.id), else: %{total_workouts: 0, recent_workouts: 0, total_sets: 0, muscle_volume_7d: %{}}

        # Format muscle volume for system prompt
        volume_summary = if map_size(workout_stats.muscle_volume_7d) > 0 do
          workout_stats.muscle_volume_7d
          |> Enum.map(fn {muscle, volumes} ->
            "  - #{muscle}: #{round(volumes.direct)} direct sets, #{round(volumes.effective)} effective sets"
          end)
          |> Enum.join("\n")
        else
          "  No volume data yet"
        end

        %{
          role: :system,
          content: """
          You are an AI fitness assistant in a workout tracking app called Scope Application.

          IMPORTANT CONTEXT:
          - You are chatting with a CLIENT named "#{user.name || "Unknown"}"
          - Client ID: #{if client, do: client.id, else: "Unknown"}
          #{if trainer_info, do: "- Their trainer is: #{trainer_info.name}", else: ""}
          - When they ask "who am I?" or "what's my name?", tell them: "You are #{user.name}, a client"
          - When they ask "what's my role?", tell them: "You are a client"
          #{if trainer_info, do: "- When they ask about their trainer, tell them: \"Your trainer is #{trainer_info.name}\"", else: ""}

          CLIENT'S WORKOUT STATS:
          - Total workouts completed: #{workout_stats.total_workouts}
          - Workouts in last 7 days: #{workout_stats.recent_workouts}
          - Total sets logged: #{workout_stats.total_sets}

          MUSCLE VOLUME (Last 7 Days):
#{volume_summary}

          When they ask "how many workouts have I done?" or similar:
          - Tell them: "You've completed #{workout_stats.total_workouts} total workouts, with #{workout_stats.recent_workouts} in the last 7 days. That's #{workout_stats.total_sets} total sets logged!"
          #{if map_size(workout_stats.muscle_volume_7d) > 0 do
            "- Then mention their volume breakdown by muscle group from the data above, highlighting which muscles they've trained the most"
          else
            ""
          end}

          YOUR CAPABILITIES FOR CLIENTS:
          1. Answer general fitness and exercise questions
          2. Provide motivation and encouragement based on their progress
          3. Explain exercise techniques and form cues
          4. Discuss nutrition basics and healthy habits
          5. Help interpret their workout program (but defer to their trainer for changes)
          6. Celebrate their workout achievements and consistency
          7. **TRACK WORKOUTS** - You can help them log their workouts!

          WORKOUT TRACKING FEATURE:
          When the client wants to track/log a workout, follow this conversational flow:

          Step 1: Client says "track my workout" or "log my workout"
          Step 2: Ask them: "What's the workout name and what date did you do it? (e.g., 'Push Day, today')"
          Step 3: Client provides name and date
          Step 4: Ask them: "Great! What exercises did you do? Format: Exercise Name - sets x reps @ weight. For example: 'Bench Press - 3x8@80kg, Overhead Press - 3x10@50kg'"
          Step 5: Client provides exercises
          Step 6: Create the workout using this EXACT format:

          [CREATE_WORKOUT]WorkoutName|date|ExerciseName:sets:reps:weight,ExerciseName:sets:reps:weight[/CREATE_WORKOUT]

          IMPORTANT RULES FOR WORKOUT CREATION:
          - Exercise names MUST match exactly what's in the database (e.g., "Bench Press", "Squat", "Deadlift")
          - Common exercises: Bench Press, Squat, Deadlift, Overhead Press, Barbell Row, Pull Up, Lat Pulldown, Leg Press, Leg Curl, Leg Extension, Bicep Curl, Tricep Extension
          - Date can be: "today", "yesterday", or ISO format
          - Format example: [CREATE_WORKOUT]Push Day|today|Bench Press:3:8:80,Overhead Press:3:10:50[/CREATE_WORKOUT]
          - After creating, tell them: "I've created your workout! You can view it in your workouts page."

          RESPONSE STYLE FOR CLIENTS:
          - Use friendly, encouraging language
          - Explain fitness concepts in simple terms
          - Be supportive and motivational
          - Focus on their personal fitness journey
          - Celebrate their progress and effort
          - When discussing their stats, be enthusiastic and positive
          - Guide them step-by-step when tracking workouts

          IMPORTANT BOUNDARIES:
          - Always defer to their trainer (#{if trainer_info, do: trainer_info.name, else: "their assigned trainer"}) for program changes
          - You can help them LOG workouts they've completed, but not design new programs
          - For specific programming questions, suggest they ask their trainer
          - You provide general guidance and support only

          Keep responses encouraging, accessible, and focused on their fitness journey.
          """
        }

      _ ->
        %{
          role: :system,
          content: "You are a helpful fitness AI assistant. You are chatting with #{user.name || "a user"}."
        }
    end
  end

  defp get_trainer_client_stats(trainer_id) do
    alias Crohnjobs.Clients.Client
    alias Crohnjobs.Training.Workout
    import Ecto.Query

    # Get total clients for this trainer
    total_clients = Repo.aggregate(
      from(c in Client, where: c.trainer_id == ^trainer_id),
      :count,
      :id
    )

    # Get active clients (those with workouts in the last 7 days)
    seven_days_ago = DateTime.utc_now() |> DateTime.add(-7, :day)

    active_clients = Repo.aggregate(
      from(w in Workout,
        join: c in Client,
        on: w.client_id == c.id,
        where: c.trainer_id == ^trainer_id and w.inserted_at >= ^seven_days_ago,
        distinct: w.client_id
      ),
      :count,
      :id
    )

    %{
      total_clients: total_clients,
      active_clients: active_clients
    }
  end

  defp get_client_workout_stats(client_id) do
    alias Crohnjobs.Training.Workout
    alias Crohnjobs.Training.WorkoutDetails
    import Ecto.Query

    # Get total workouts for this client
    total_workouts = Repo.aggregate(
      from(w in Workout, where: w.client_id == ^client_id),
      :count,
      :id
    )

    # Get workouts in the last 7 days
    seven_days_ago = DateTime.utc_now() |> DateTime.add(-7, :day)

    recent_workouts = Repo.aggregate(
      from(w in Workout,
        where: w.client_id == ^client_id and w.inserted_at >= ^seven_days_ago
      ),
      :count,
      :id
    )

    # Get total sets logged
    total_sets = Repo.aggregate(
      from(wd in WorkoutDetails,
        join: w in Workout,
        on: wd.workout_id == w.id,
        where: w.client_id == ^client_id
      ),
      :count,
      :id
    )

    # Get workout details from the last 7 days for volume calculation
    recent_workout_details =
      Repo.all(
        from(wd in WorkoutDetails,
          join: w in Workout,
          on: wd.workout_id == w.id,
          where: w.client_id == ^client_id and w.inserted_at >= ^seven_days_ago,
          select: wd
        )
      )

    # Calculate volume for the last 7 days
    muscle_volume_7d = calculate_muscle_volume(recent_workout_details)

    %{
      total_workouts: total_workouts,
      recent_workouts: recent_workouts,
      total_sets: total_sets,
      muscle_volume_7d: muscle_volume_7d
    }
  end

  defp calculate_muscle_volume(workout_details) do
    alias Crohnjobs.Exercises.ExerciseMuscleContribution
    import Ecto.Query

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

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-purple-50 to-blue-50">
      <!-- Header -->
      <header class="bg-white shadow-sm border-b border-gray-200">
        <div class="max-w-4xl mx-auto px-4 py-4 flex items-center justify-between">
          <div class="flex items-center gap-4">
            <.link navigate={if @user.role == "trainer", do: "/trainer/dashboard", else: "/client/dashboard"} class="flex items-center gap-2 text-gray-600 hover:text-gray-900 transition">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M9.707 16.707a1 1 0 01-1.414 0l-6-6a1 1 0 010-1.414l6-6a1 1 0 011.414 1.414L5.414 9H17a1 1 0 110 2H5.414l4.293 4.293a1 1 0 010 1.414z" clip-rule="evenodd" />
              </svg>
              Back
            </.link>
            <div class="h-6 w-px bg-gray-300"></div>
            <div class="flex items-center gap-2">
              <div class="w-10 h-10 bg-gradient-to-br from-purple-500 to-blue-500 rounded-full flex items-center justify-center">
                <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
                </svg>
              </div>
              <div>
                <h1 class="text-xl font-bold text-gray-900">AI Coach</h1>
                <p class="text-xs text-gray-500">Your personal fitness assistant</p>
              </div>
            </div>
          </div>
          <div class="flex items-center gap-3">
            <span class="text-sm text-gray-600"><%= @user.name %></span>
            <div class="w-8 h-8 bg-purple-500 rounded-full flex items-center justify-center text-sm font-medium text-white">
              <%= String.first(@user.name) %>
            </div>
          </div>
        </div>
      </header>

      <!-- Chat Container -->
      <div class="max-w-4xl mx-auto p-4">
        <div class="bg-white rounded-2xl shadow-xl overflow-hidden border border-gray-200">
          <!-- Messages Area -->
          <div class="h-[calc(100vh-220px)] overflow-y-auto p-6" id="messages-container" phx-hook="ScrollBottom">
            <%= if length(@messages) == 0 do %>
              <div class="flex flex-col items-center justify-center h-full text-gray-400">
                <div class="w-20 h-20 bg-gradient-to-br from-purple-100 to-blue-100 rounded-full flex items-center justify-center mb-4">
                  <svg class="w-10 h-10 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
                  </svg>
                </div>
                <h3 class="text-lg font-semibold text-gray-700 mb-2">Start a conversation</h3>
                <p class="text-sm text-gray-500 text-center max-w-md">
                  Ask me anything about fitness, workouts, nutrition, or your training!
                </p>
                <div class="mt-6 flex flex-wrap gap-2 justify-center max-w-md">
                  <button phx-click="send" phx-value-text="Who am I?" class="px-3 py-2 bg-purple-50 text-purple-700 rounded-lg text-sm hover:bg-purple-100 transition">
                    Who am I?
                  </button>
                  <button phx-click="send" phx-value-text="What's my role?" class="px-3 py-2 bg-blue-50 text-blue-700 rounded-lg text-sm hover:bg-blue-100 transition">
                    What's my role?
                  </button>
                  <button phx-click="send" phx-value-text="Help me with my training" class="px-3 py-2 bg-green-50 text-green-700 rounded-lg text-sm hover:bg-green-100 transition">
                    Help with training
                  </button>
                </div>
              </div>
            <% else %>
              <div class="space-y-4">
                <%= for msg <- @messages do %>
                  <%= if msg.role == :user do %>
                    <div class="flex justify-end">
                      <div class="max-w-md">
                        <div class="text-xs text-gray-500 text-right mb-1">You</div>
                        <div class="bg-gradient-to-r from-purple-500 to-blue-500 text-white px-4 py-3 rounded-2xl rounded-br-md shadow-sm">
                          <%= msg.content %>
                        </div>
                      </div>
                    </div>
                  <% else %>
                    <div class="flex justify-start">
                      <div class="flex gap-3 max-w-md">
                        <div class="w-8 h-8 bg-gradient-to-br from-purple-500 to-blue-500 rounded-full flex-shrink-0 flex items-center justify-center">
                          <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
                          </svg>
                        </div>
                        <div>
                          <div class="text-xs text-purple-600 mb-1 font-medium">AI Coach</div>
                          <div class="bg-gray-50 border border-gray-200 px-4 py-3 rounded-2xl rounded-bl-md shadow-sm">
                            <%= msg.content %>
                          </div>
                        </div>
                      </div>
                    </div>
                  <% end %>
                <% end %>

                <%= if @loading do %>
                  <div class="flex justify-start">
                    <div class="flex gap-3 max-w-md">
                      <div class="w-8 h-8 bg-gradient-to-br from-purple-500 to-blue-500 rounded-full flex-shrink-0 flex items-center justify-center">
                        <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
                        </svg>
                      </div>
                      <div>
                        <div class="text-xs text-purple-600 mb-1 font-medium">AI Coach</div>
                        <div class="bg-gray-50 border border-gray-200 px-4 py-3 rounded-2xl rounded-bl-md shadow-sm">
                          <div class="flex items-center gap-2">
                            <div class="w-2 h-2 bg-purple-500 rounded-full animate-bounce"></div>
                            <div class="w-2 h-2 bg-purple-500 rounded-full animate-bounce" style="animation-delay: 0.2s"></div>
                            <div class="w-2 h-2 bg-purple-500 rounded-full animate-bounce" style="animation-delay: 0.4s"></div>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>

          <!-- Message Input -->
          <div class="border-t border-gray-200 p-4 bg-white">
            <form phx-submit="send" class="flex gap-3">
              <input
                type="text"
                name="text"
                value={@text}
                autocomplete="off"
                placeholder="Ask me anything..."
                disabled={@loading}
                class="flex-1 border border-gray-300 rounded-full px-5 py-3 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent disabled:bg-gray-100"
              />
              <button
                type="submit"
                disabled={@loading}
                class="bg-gradient-to-r from-purple-500 to-blue-500 text-white px-6 py-3 rounded-full hover:from-purple-600 hover:to-blue-600 transition flex items-center gap-2 font-medium disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <span>Send</span>
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                  <path d="M10.894 2.553a1 1 0 00-1.788 0l-7 14a1 1 0 001.169 1.409l5-1.429A1 1 0 009 15.571V11a1 1 0 112 0v4.571a1 1 0 00.725.962l5 1.428a1 1 0 001.17-1.408l-7-14z" />
                </svg>
              </button>
            </form>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
