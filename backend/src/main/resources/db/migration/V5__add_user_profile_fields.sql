
ALTER TABLE users
    ADD COLUMN username VARCHAR(30);

ALTER TABLE users
    ADD COLUMN biography VARCHAR(500);

ALTER TABLE users
    ADD COLUMN avatar_url VARCHAR(2048);

CREATE UNIQUE INDEX uq_users_username
    ON users (username);

ALTER TABLE users
    ADD CONSTRAINT ck_users_username
    CHECK (
        username IS NULL
        OR (
            username = LOWER(username)
            AND CHAR_LENGTH(username) BETWEEN 3 AND 30
        )
    );
