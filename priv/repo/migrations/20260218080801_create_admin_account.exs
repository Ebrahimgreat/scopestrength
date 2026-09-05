defmodule Scopestrength.Repo.Migrations.CreateAdminAccount do
  use Ecto.Migration

  # This migration originally inserted a hardcoded personal admin account.
  # The admin role has since been removed from the app entirely, so there is
  # nothing for this migration to do. Left as a no-op rather than deleted so
  # the migration history stays contiguous for installs that already ran it.
  def up, do: :ok
  def down, do: :ok
end
