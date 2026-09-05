-- Empties every user-facing table in ScopeStrength, keeping the database,
-- schema, migrations history and Oban's own tables intact.
--
-- Deliberately NOT included: schema_migrations, oban_jobs, oban_peers (not
-- app data), measurements/measurementdata (dead tables, no code references
-- them).
--
-- RESTART IDENTITY resets every serial/identity sequence back to 1, so the
-- next inserted row in each table gets id 1 again. CASCADE follows foreign
-- keys so child rows go with their parents in one statement -- listing every
-- table already covers that, this is just insurance against a dependency
-- order you didn't think of.
--
-- Run this only against the database you intend to wipe. It does not ask
-- for confirmation.

TRUNCATE TABLE
  client_notes,
  client_progressions,
  client_weight,
  clients,
  exercise_muscle_contribution,
  exercises,
  equipment,
  muscles,
  invites,
  leads,
  message_attachments,
  messages,
  notifications,
  programme_details,
  programme_template,
  programmeuser,
  programme,
  progress_photos,
  trainers,
  users,
  users_tokens,
  workout_details,
  workouts
RESTART IDENTITY CASCADE;
