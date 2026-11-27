package com.capitulo0.backend.library.entity;

import jakarta.persistence.*;
import java.io.Serializable;

@Entity
@Table(name = "saved_community_stories")
@IdClass(SavedCommunityStory.Key.class)
public class SavedCommunityStory {
    @Id @Column(name = "user_id", nullable = false) private Long userId;
    @Id @Column(name = "story_key", nullable = false, length = 64) private String storyKey;
    protected SavedCommunityStory() {}
    public SavedCommunityStory(Long userId, String storyKey) { this.userId = userId; this.storyKey = storyKey; }
    public Long getUserId() { return userId; }
    public String getStoryKey() { return storyKey; }
    public static class Key implements Serializable {
        public Long userId;
        public String storyKey;
        public Key() {}
        public Key(Long userId, String storyKey) { this.userId = userId; this.storyKey = storyKey; }
        @Override public boolean equals(Object value) { return value instanceof Key other && java.util.Objects.equals(userId, other.userId) && java.util.Objects.equals(storyKey, other.storyKey); }
        @Override public int hashCode() { return java.util.Objects.hash(userId, storyKey); }
    }
}
