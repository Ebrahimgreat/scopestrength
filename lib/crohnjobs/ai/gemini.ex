defmodule Crohnjobs.AI.Gemini do
  alias Crohnjobs.Repo
  alias Crohnjobs.Exercises.Exercise
  import Ecto.Query

  defp api_key do
    case System.get_env("GEMINI_API_KEY") do
      nil -> {:error, :api_key_not_set}
      "" -> {:error, :api_key_not_set}
      key -> {:ok, key}
    end
  end

  @doc """
  Checks if Gemini API is configured and available.
  """
  def available? do
    case api_key() do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end

  @doc """
  Returns the API key status for external use.
  Returns {:ok, key} if configured, {:error, reason} otherwise.
  """
  def api_key_status do
    api_key()
  end

  @doc """
  Simple chat function for conversational AI.
  """
  def chat(message, context \\ []) do
    case api_key() do
      {:error, :api_key_not_set} ->
        {:error, "Gemini API key not configured. Please set GEMINI_API_KEY environment variable."}

      {:ok, key} ->
        # Build conversation history
        history = Enum.map(context, fn %{role: role, content: content} ->
          %{
            role: if(role == :user, do: "user", else: "model"),
            parts: [%{text: content}]
          }
        end)

        # Add current message
        contents = history ++ [%{role: "user", parts: [%{text: message}]}]

        body = %{
          contents: contents,
          systemInstruction: %{
            parts: [%{text: system_prompt()}]
          }
        }

        headers = [{"content-type", "application/json"}]
        url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=#{key}"

        case HTTPoison.post(url, Jason.encode!(body), headers) do
          {:ok, %{status: 200, body: response_body}} ->
            case Jason.decode(response_body) do
              {:ok, decoded} ->
                extract_chat_response(decoded)
              {:error, _} ->
                {:error, "Failed to parse response"}
            end

          {:ok, %{status: status, body: body}} ->
            {:error, "API error (#{status}): #{body}"}

          {:error, %HTTPoison.Error{reason: reason}} ->
            {:error, "Network error: #{inspect(reason)}"}
        end
    end
  end

  defp system_prompt do
    """
    You are a helpful fitness AI assistant for a workout tracking app called CrohnJobs.

    Your main capabilities:
    1. Help users track their workouts by parsing natural language
    2. Answer fitness-related questions
    3. Provide workout suggestions and tips
    4. Analyze workout progress

    When users describe their workouts, parse them and return structured data.
    Be encouraging, helpful, and concise. Use emojis sparingly to keep things friendly.

    If a user wants to log a workout, ask them to describe what they did (exercises, sets, reps, weight).
    """
  end

  defp extract_chat_response(%{
    "candidates" => [
      %{
        "content" => %{
          "parts" => [%{"text" => text}]
        }
      } | _
    ]
  }) do
    {:ok, String.trim(text)}
  end

  defp extract_chat_response(_), do: {:error, "Invalid response format"}

  def generate_workout(user_request) when is_binary(user_request) do
    case api_key() do
      {:error, reason} -> {:error, reason}
      {:ok, key} ->
        exercises = list_available_exercises()

        body = %{
          contents: [
            %{
              parts: [
                %{text: build_generation_prompt(user_request, exercises)}
              ]
            }
          ]
        }

        headers = [{"content-type", "application/json"}]
        url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=#{key}"

        with {:ok, %{status: 200, body: response_body}} <-
               HTTPoison.post(url, Jason.encode!(body), headers),
             {:ok, decoded} <- Jason.decode(response_body),
             {:ok, parsed} <- extract_json(decoded) do
          {:ok, parsed}
        else
          error -> {:error, error}
        end
    end
  end

  defp list_available_exercises do
    Repo.all(from e in Exercise, select: %{name: e.name, type: e.type, equipment: e.equipment})
  end

  defp build_generation_prompt(user_request, exercises) do
    exercise_list = exercises
    |> Enum.map(fn e -> "- #{e.name} (#{e.type}, #{e.equipment})" end)
    |> Enum.join("\n")

    """
    You are a professional fitness coach creating personalized workouts.

    AVAILABLE EXERCISES (you MUST only use exercises from this list):
    #{exercise_list}

    USER REQUEST:
    #{user_request}

    Rules:
    - Output ONLY valid JSON
    - No explanations or markdown
    - Only use exercise names EXACTLY as listed above
    - Create a balanced workout based on the user's request
    - Include appropriate sets, reps, and weights for each exercise
    - If user doesn't specify, create a 4-6 exercise workout

    JSON format:
    {
      "workout_name": string,
      "exercises": [
        {
          "name": string (must match exactly from list above),
          "sets": [
            {
              "set": number,
              "reps": number,
              "weight": number | null
            }
          ]
        }
      ]
    }
    """
  end


  defp extract_json(%{
    "candidates" => [
      %{
        "content" => %{
          "parts" => [
            %{"text" => text}
          ]
        }
      }
    ]
  }) do
# Gemini sometimes returns whitespace — trim it
cleaned = String.trim(text)

Jason.decode(cleaned)
end

defp extract_json(_), do: {:error, :invalid_gemini_response}


  # Parses workout note and returns flat list of sets for Training module
  def parse_workout_note(text) when is_binary(text) do
    case parse_workout(text) do
      {:ok, %{"exercises" => exercises}} ->
        sets = Enum.flat_map(exercises, fn exercise ->
          exercise_name = exercise["name"]
          Enum.map(exercise["sets"], fn set ->
            %{
              "exercise" => exercise_name,
              "set" => set["set"],
              "reps" => set["reps"],
              "weight" => set["weight"],
              "rir" => set["rir"]
            }
          end)
        end)
        {:ok, sets}

      {:ok, _} ->
        {:error, :invalid_format}

      error ->
        error
    end
  end

  def parse_workout(text) when is_binary(text) do
    case api_key() do
      {:error, reason} -> {:error, reason}
      {:ok, key} ->
        body = %{
          contents: [
            %{
              parts: [
                %{text: build_prompt(text)}
              ]
            }
          ]
        }

        headers = [{"content-type", "application/json"}]
        url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=#{key}"

        with {:ok, %{status: 200, body: response_body}} <-
               HTTPoison.post(url, Jason.encode!(body), headers),
             {:ok, decoded} <- Jason.decode(response_body),
             {:ok, parsed} <- extract_json(decoded) do
          {:ok, parsed}
        else
          error ->
            {:error, error}
        end
    end
  end

  defp build_prompt(text) do
    """
    You are a workout parsing engine.

    Rules:
    - Output ONLY valid JSON
    - No explanations
    - No markdown
    - No coaching or advice
    - No extra keys
    - If information is missing, use null

    JSON format:
    {
      "workout_name": string | null,
      "date": string | null,
      "exercises": [
        {
          "name": string,
          "sets": [
            {
              "set": number,
              "reps": number | null,
              "weight": number | null
            }
          ]
        }
      ]
    }

    User message:
    #{text}
    """
  end

end
