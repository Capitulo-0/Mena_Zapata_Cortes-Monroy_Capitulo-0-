package com.capitulo0.backend.social.entity;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "chapter_comments")
public class ChapterComment {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(name = "story_key", nullable = false, updatable = false, length = 64)
    private String storyKey;
    @Column(name = "chapter_id", nullable = false, updatable = false, length = 64)
    private String chapterId;
    @Column(name = "user_id", nullable = false, updatable = false)
    private Long userId;
    @Column(name = "parent_id", updatable = false)
    private Long parentId;
    @Column(nullable = false, columnDefinition = "text")
    private String content;
    @Column(nullable = false)
    private boolean anonymous;
    @Column(nullable = false)
    private boolean hidden;
    @Column(nullable = false)
    private boolean deleted;
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected ChapterComment() {}
    public ChapterComment(String storyKey, String chapterId, Long userId, Long parentId, String content, boolean anonymous) {
        this.storyKey = storyKey;
        this.chapterId = chapterId;
        this.userId = userId;
        this.parentId = parentId;
        this.content = content;
        this.anonymous = anonymous;
    }
    @PrePersist void onCreate() { createdAt = updatedAt = Instant.now(); }
    @PreUpdate void onUpdate() { updatedAt = Instant.now(); }
    public Long getId() { return id; }
    public String getStoryKey() { return storyKey; }
    public String getChapterId() { return chapterId; }
    public Long getUserId() { return userId; }
    public Long getParentId() { return parentId; }
    public String getContent() { return content; }
    public boolean isAnonymous() { return anonymous; }
    public boolean isHidden() { return hidden; }
    public boolean isDeleted() { return deleted; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
    public void edit(String content, boolean anonymous) { this.content = content; this.anonymous = anonymous; }
    public void markDeleted() { this.deleted = true; }
    public void setHidden(boolean hidden) { this.hidden = hidden; }
}
