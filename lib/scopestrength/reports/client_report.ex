defmodule Scopestrength.Reports.ClientReport do
  import Ecto.Query
  alias Scopestrength.Repo
  alias Scopestrength.Clients.Client
  alias Scopestrength.ClientWeight.ClientWeights
  alias Scopestrength.Training.{Workout, WorkoutDetails}
  alias Scopestrength.Exercises.Exercise
  alias Elixlsx.{Workbook, Sheet}

  def generate(client_id) do
    client = Repo.get!(Client, client_id) |> Repo.preload(:user)
    client_name = client.user.name || "Client"

    weight_sheet = build_weight_sheet(client_id)
    workout_sheet = build_workout_sheet(client_id)

    workbook = %Workbook{sheets: [weight_sheet, workout_sheet]}

    file_name = "#{String.replace(client_name, " ", "_")}_report_#{Date.to_string(Date.utc_today())}.xlsx"
    tmp_path = Path.join(System.tmp_dir!(), file_name)

    {:ok, _} = Elixlsx.write_to(workbook, tmp_path)

    {:ok, tmp_path, file_name}
  end

  defp build_weight_sheet(client_id) do
    weights =
      from(w in ClientWeights,
        where: w.client_id == ^client_id,
        order_by: [asc: w.date]
      )
      |> Repo.all()

    header = [["Date", "Weight (kg)"]]

    rows =
      Enum.map(weights, fn w ->
        [to_string(w.date), decimal_to_string(w.weight)]
      end)

    %Sheet{name: "Weight History", rows: header ++ rows}
  end

  defp build_workout_sheet(client_id) do
    details =
      from(wd in WorkoutDetails,
        join: w in Workout,
        on: wd.workout_id == w.id,
        join: e in Exercise,
        on: wd.exercise_id == e.id,
        where: w.client_id == ^client_id,
        order_by: [asc: w.date, asc: w.id, asc: e.name, asc: wd.set],
        select: %{
          date: w.date,
          workout_name: w.name,
          exercise_name: e.name,
          set: wd.set,
          reps: wd.reps,
          weight: wd.weight,
          side: wd.side,
          notes: wd.notes
        }
      )
      |> Repo.all()

    header = [["Date", "Workout", "Exercise", "Set", "Reps", "Weight (kg)", "Side", "Notes"]]

    rows =
      Enum.map(details, fn d ->
        [
          format_datetime(d.date),
          d.workout_name || "",
          d.exercise_name || "",
          d.set || "",
          d.reps || "",
          d.weight || "",
          d.side || "",
          d.notes || ""
        ]
      end)

    %Sheet{name: "Workout Log", rows: header ++ rows}
  end

  defp decimal_to_string(nil), do: ""
  defp decimal_to_string(%Decimal{} = d), do: Decimal.to_string(d)
  defp decimal_to_string(val), do: to_string(val)

  defp format_datetime(nil), do: ""
  defp format_datetime(%DateTime{} = dt), do: Calendar.strftime(dt, "%Y-%m-%d %H:%M")
  defp format_datetime(%Date{} = d), do: Date.to_string(d)
  defp format_datetime(val), do: to_string(val)
end
