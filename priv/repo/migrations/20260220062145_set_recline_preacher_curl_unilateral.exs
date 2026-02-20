defmodule Crohnjobs.Repo.Migrations.SetReclinePreacherCurlUnilateral do
  use Ecto.Migration

  def up do
    execute """
    UPDATE exercises SET is_unilateral = true
    WHERE name = 'Recline Preacher Curl(One Arm)';
    """
  end

  def down do
    execute """
    UPDATE exercises SET is_unilateral = false
    WHERE name = 'Recline Preacher Curl(One Arm)';
    """
  end
end
