defmodule Crohnjobs.DownloadProgramme do
  def downloadProgramme(%{programme: programme}) do
    programme_name = programme.name
    programme_description = programme.description

    programme_templates =
      Enum.map(programme.programmeTemplates, fn template ->
        %{
          template_name: template.name,
          exercises: Enum.map(template.programmeDetails, fn detail ->
            %{
              name: detail.exercise.name,
              reps: detail.reps,
              set: detail.set
            }
          end)
        }
      end)

    case File.open("programme.txt", [:write, :utf8]) do
      {:ok, file} ->
        IO.puts(file, "Programme Name: #{programme_name}")
        IO.puts(file, "Programme Description: #{programme_description}")
        IO.puts(file, "")

        Enum.each(programme_templates, fn template ->
          IO.puts(file, "Template : #{template.template_name}")
          Enum.each(template.exercises, fn exercise ->
            IO.puts(
              file,
              "  Exercise: #{exercise.name}, Set: #{exercise.set}, Reps: #{exercise.reps}"
            )
          end)

          IO.puts(file, "") # Extra line between templates
        end)

        File.close(file)

      {:error, reason} ->
        IO.inspect(reason, label: "Error opening file")
    end
  end
end
