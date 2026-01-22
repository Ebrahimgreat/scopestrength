defmodule Crohnjobs.AI.Gemini do
  alias Crohnjobs.Repo
  alias Crohnjobs.Exercises.Exercise
  import Ecto.Query

  defp api_key do
    System.fetch_env!("GEMINI_API_KEY")
  end

  def generate_workout(user_request) when is_binary(user_request) do
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
    url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=#{api_key()}"

    with {:ok, %{status: 200, body: response_body}} <-
           HTTPoison.post(url, Jason.encode!(body), headers),
         {:ok, decoded} <- Jason.decode(response_body),
         {:ok, parsed} <- extract_json(decoded) do
      {:ok, parsed}
    else
      error -> {:error, error}
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
    body = %{
      contents: [
        %{
          parts: [
            %{text: build_prompt(text)}
          ]
        }
      ]
    }

    headers = [
      {"content-type", "application/json"}
    ]
    url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=#{api_key()}"


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
