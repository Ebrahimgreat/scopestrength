defmodule Crohnjobs.Repo.Migrations.CreateAdminAccount do
  use Ecto.Migration

  def up do
    # Hash the password using Bcrypt (same algorithm used in the app)
    hashed_password = Bcrypt.hash_pwd_salt("REDACTED-PASSWORD")

    # Insert admin user
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
