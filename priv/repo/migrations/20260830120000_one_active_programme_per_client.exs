defmodule Scopestrength.Repo.Migrations.OneActiveProgrammePerClient do
  use Ecto.Migration

  @moduledoc """
  A client may only be on one programme at a time. Nothing enforced that, so
  assigning from the programme page inserted a second active row rather than
  replacing the first, and `Repo.get_by(ProgrammeUser, is_active: true)` then
  raised `Ecto.MultipleResultsError` on that client's dashboard.

  Inactive rows are history -- a client moved off a programme keeps the old
  row -- so the index is partial and constrains only the active ones.
  """

  def up do
    execute("""
    UPDATE programmeuser SET is_active = false
    WHERE is_active
      AND id NOT IN (
        SELECT DISTINCT ON (client_id) id
        FROM programmeuser
        WHERE is_active
        ORDER BY client_id, inserted_at DESC, id DESC
      )
    """)

    create unique_index(:programmeuser, [:client_id],
             where: "is_active",
             name: :programmeuser_one_active_per_client
           )
  end

  def down do
    drop index(:programmeuser, [:client_id], name: :programmeuser_one_active_per_client)
  end
end
