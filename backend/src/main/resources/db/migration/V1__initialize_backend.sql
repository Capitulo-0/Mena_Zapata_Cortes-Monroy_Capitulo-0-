-- Technical marker only: no users, books, authentication or library schema.
CREATE TABLE backend_bootstrap (
    id INTEGER PRIMARY KEY,
    service_name VARCHAR(64) NOT NULL,
    initialized_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT backend_bootstrap_singleton CHECK (id = 1)
);

INSERT INTO backend_bootstrap (id, service_name)
VALUES (1, 'capitulo-0-backend');
