-- Existing MVP accounts remain unlinked until a verified Firebase identity is available.
-- PostgreSQL UNIQUE allows multiple NULL values; no UID is inferred or generated here.
ALTER TABLE users ADD COLUMN firebase_uid VARCHAR(128);
ALTER TABLE users ADD CONSTRAINT uq_users_firebase_uid UNIQUE (firebase_uid);
