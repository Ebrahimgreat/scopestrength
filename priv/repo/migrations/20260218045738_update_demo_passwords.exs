defmodule Scopestrength.Repo.Migrations.UpdateDemoPasswords do
  use Ecto.Migration

  def up do
    hashed = Bcrypt.hash_pwd_salt("Demodemo1234")

    execute """
    UPDATE users
    SET hashed_password = '#{hashed}'
    WHERE email LIKE 'demo_%@scopestrength.com'
    """
  end

  def down do
    :ok
  end
end
