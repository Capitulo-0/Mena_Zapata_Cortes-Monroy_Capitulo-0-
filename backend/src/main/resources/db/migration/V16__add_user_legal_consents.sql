-- Los usuarios existentes conservan NULL: no se presume consentimiento retroactivo.
ALTER TABLE users
    ADD COLUMN terms_accepted_at TIMESTAMPTZ,
    ADD COLUMN privacy_accepted_at TIMESTAMPTZ,
    ADD COLUMN terms_version VARCHAR(32),
    ADD COLUMN privacy_version VARCHAR(32);
