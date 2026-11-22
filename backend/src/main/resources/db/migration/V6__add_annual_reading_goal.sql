ALTER TABLE users
    ADD COLUMN annual_reading_goal INTEGER NOT NULL DEFAULT 25;

ALTER TABLE users
    ADD CONSTRAINT ck_users_annual_reading_goal
    CHECK (annual_reading_goal > 0);