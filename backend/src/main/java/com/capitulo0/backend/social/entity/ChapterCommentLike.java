package com.capitulo0.backend.social.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.io.Serializable;
import java.util.Objects;

@Entity
@Table(name = "chapter_comment_likes")
@IdClass(ChapterCommentLike.Key.class)
public class ChapterCommentLike {
    @Id @Column(name = "comment_id", nullable = false)
    private Long commentId;
    @Id @Column(name = "user_id", nullable = false)
    private Long userId;
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    protected ChapterCommentLike() {}
    public ChapterCommentLike(Long commentId, Long userId) {
        this.commentId = commentId;
        this.userId = userId;
    }
    @PrePersist void onCreate() { createdAt = Instant.now(); }
    public Long getCommentId() { return commentId; }
    public Long getUserId() { return userId; }
    public Instant getCreatedAt() { return createdAt; }

    public static class Key implements Serializable {
        public Long commentId;
        public Long userId;
        public Key() {}
        public Key(Long commentId, Long userId) { this.commentId = commentId; this.userId = userId; }
        @Override public boolean equals(Object value) {
            return value instanceof Key other && Objects.equals(commentId, other.commentId)
                && Objects.equals(userId, other.userId);
        }
        @Override public int hashCode() { return Objects.hash(commentId, userId); }
    }
}
