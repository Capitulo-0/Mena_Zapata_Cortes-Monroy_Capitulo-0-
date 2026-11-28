package com.capitulo0.backend.social.entity;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "chapter_comment_reports")
public class ChapterCommentReport {
    public enum Status { PENDING, RESOLVED, DISMISSED }
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(name = "comment_id", nullable = false, updatable = false)
    private Long commentId;
    @Column(name = "user_id", nullable = false, updatable = false)
    private Long userId;
    @Column(nullable = false, columnDefinition = "text")
    private String reason;
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private Status status = Status.PENDING;
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    protected ChapterCommentReport() {}
    public ChapterCommentReport(Long commentId, Long userId, String reason) {
        this.commentId = commentId;
        this.userId = userId;
        this.reason = reason;
    }
    @PrePersist void onCreate() { createdAt = Instant.now(); }
    public Long getId() { return id; }
    public Long getCommentId() { return commentId; }
    public Long getUserId() { return userId; }
    public String getReason() { return reason; }
    public Status getStatus() { return status; }
    public Instant getCreatedAt() { return createdAt; }
}
