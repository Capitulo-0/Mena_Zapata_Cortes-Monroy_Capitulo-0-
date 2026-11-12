-- Existing manual books retain null external identity and unchanged metadata.
ALTER TABLE books ADD COLUMN google_volume_id VARCHAR(128);
ALTER TABLE books ADD COLUMN external_metadata TEXT;
ALTER TABLE books ADD CONSTRAINT uq_books_google_volume UNIQUE (google_volume_id);
