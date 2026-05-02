defmodule Scopestrength.Repo.Migrations.UpdateDemoPasswords do
  use Ecto.Migration

  def up do
    # Update all demo accounts to use the standard demo password "Demodemo1234"
    hashed = Bcrypt.hash_pwd_salt("Demodemo1234")

    execute """
    UPDATE users
    SET hashed_password = '#{hashed}'
    WHERE email LIKE 'demo_%@scopestrength.com'
    """
  end

  def down do
    # Cannot reverse password changes
    :ok
  end
end
