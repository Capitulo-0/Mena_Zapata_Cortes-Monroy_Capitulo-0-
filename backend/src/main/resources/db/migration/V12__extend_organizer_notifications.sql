
ALTER TABLE user_notifications
DROP CONSTRAINT ck_user_notifications_type;

ALTER TABLE user_notifications
ADD CONSTRAINT ck_user_notifications_type
CHECK (
    type IN (
        'FOLLOW_REQUEST',
        'NEW_FOLLOWER',
        'FOLLOW_ACCEPTED',
        'ORGANIZER_APPROVED',
        'ORGANIZER_REJECTED'
    )
);

ALTER TABLE user_notifications
ADD CONSTRAINT ck_user_notifications_organizer_follow
CHECK (
    type NOT IN ('ORGANIZER_APPROVED', 'ORGANIZER_REJECTED')
    OR follow_id IS NULL
);
