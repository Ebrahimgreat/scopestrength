defmodule Scopestrength.Repo.Migrations.CreateAdminAccount do
  use Ecto.Migration

  def up do
    hashed_password = Bcrypt.hash_pwd_salt("REDACTED-PASSWORD")

    execute """
    INSERT INTO users (email, name, role, type, hashed_password, confirmed_at, inserted_at, updated_at)
    VALUES (
      'ebrahimgreat@gmail.com',
      'Ebrahim Admin',
      'admin',
      'normal',
      '#{hashed_password}',
      NOW(),
      NOW(),
      NOW()
    )
    ON CONFLICT (email) DO NOTHING;
    """
  end

  def down do
    execute """
    DELETE FROM users WHERE email = 'ebrahimgreat@gmail.com' AND role = 'admin';
    """
  end
end
