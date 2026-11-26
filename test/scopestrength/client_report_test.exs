defmodule Scopestrength.Reports.ClientReportTest do
  use Scopestrength.DataCase, async: true

  import Scopestrength.ExercisesFixtures
  import Scopestrength.PeopleFixtures
  import Scopestrength.RecordsFixtures
  import Scopestrength.TrainingFixtures

  alias Scopestrength.Reports.ClientReport

  test "generate_for_trainer/2 writes a spreadsheet with weight and workout sheets" do
    client =
      client_fixture(%{
        user: Scopestrength.AccountFixtures.client_user_fixture(%{name: "Alex Smith"})
      })

    client_weight_fixture(%{client_id: client.id})
    workout = workout_fixture(%{client_id: client.id})

    workout_details_fixture(%{
      workout_id: workout.id,
      exercise_id: exercise_fixture().id,
      rpe: 8.0
    })

    assert {:ok, path, file_name} =
             ClientReport.generate_for_trainer(client.trainer.user.id, client.id)

    assert String.starts_with?(file_name, "Alex_Smith_report_")
    assert String.ends_with?(file_name, ".xlsx")
    assert File.exists?(path)
    assert {:ok, [_ | _]} = :zip.list_dir(String.to_charlist(path))

    File.rm(path)
  end

  test "generate_for_trainer/2 works for a client with no data" do
    client = client_fixture()

    assert {:ok, path, _name} =
             ClientReport.generate_for_trainer(client.trainer.user.id, client.id)

    assert File.exists?(path)
    File.rm(path)
  end

  test "generate_for_trainer/2 sanitizes the client name in the download filename" do
    client =
      client_fixture(%{
        user: Scopestrength.AccountFixtures.client_user_fixture(%{name: "../unsafe\nname"})
      })

    assert {:ok, path, file_name} =
             ClientReport.generate_for_trainer(client.trainer.user.id, client.id)

    assert file_name == "unsafe_name_report_#{Date.to_string(Date.utc_today())}.xlsx"
    refute String.contains?(file_name, "..")
    refute String.contains?(file_name, "\n")
    assert File.exists?(path)

    File.rm(path)
  end
end
