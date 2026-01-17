defmodule Crohnjobs.AI.Gemini do
  defp api_key do
    System.fetch_env!("GEMINI_API_KEY")
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
    url = "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash-latest:generateContent?key=AIzaSyDdrPvnSdUT1obtBHBtbNTBlJ80uFUmt44"


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
