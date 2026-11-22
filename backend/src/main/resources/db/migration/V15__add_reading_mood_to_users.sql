-- Un único estado lector actual por usuario, sin historial ni datos de ejemplo.
ALTER TABLE users
    ADD COLUMN reading_mood_emoji VARCHAR(32),
    ADD COLUMN reading_mood_title VARCHAR(120),
    ADD COLUMN reading_mood_detail VARCHAR(500);
