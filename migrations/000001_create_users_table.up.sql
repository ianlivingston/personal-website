BEGIN;

CREATE TABLE IF NOT EXISTS users(
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username TEXT UNIQUE NOT NULL,
    password_hash BYTEA NOT NULL,
    registration_time TIMESTAMPTZ DEFAULT NOW()
);

COMMIT;