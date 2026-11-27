-- Community stories use Writer IDs, not catalog book IDs.
CREATE TABLE saved_community_stories (
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    story_key VARCHAR(64) NOT NULL REFERENCES writer_stories(story_key) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, story_key)
);
CREATE INDEX ix_saved_community_stories_story ON saved_community_stories(story_key);
