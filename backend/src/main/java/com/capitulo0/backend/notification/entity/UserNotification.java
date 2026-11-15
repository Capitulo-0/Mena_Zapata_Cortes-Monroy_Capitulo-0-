package com.capitulo0.backend.notification.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.Objects;

/**
 * Persisted notification belonging to exactly one recipient.
 *
 * Uses scalar foreign-key IDs to avoid loading other users' entities when
 * displaying the inbox. Authorization belongs in the service layer and must
 * resolve the recipient from the verified Firebase identity.
 */
@Entity
@Table(name = "user_notifications")
public class UserNotification {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "recipient_id", nullable = false)
    private Long recipientId;

    @Column(name = "actor_id", nullable = false)
    private Long actorId;

    @Column(name = "follow_id")
    private Long followId;

    @Enumerated(EnumType.STRING)
    @Column(name = "type", nullable = false, length = 30)
    private NotificationType type;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "occurred_at", nullable = false)
    private Instant occurredAt;

    @Column(name = "read_at")
    private Instant readAt;

    protected UserNotification() {
        // Required by JPA.
    }

    public UserNotification(
            Long recipientId,
            Long actorId,
            Long followId,
            NotificationType type
    ) {
        this.recipientId = Objects.requireNonNull(recipientId, "recipientId");
        this.actorId = Objects.requireNonNull(actorId, "actorId");
        this.followId = followId;
        this.type = Objects.requireNonNull(type, "type");
        if (recipientId.equals(actorId)) {
            throw new IllegalArgumentException("A user cannot notify themselves");
        }
    }

    @PrePersist
    void beforeInsert() {
        Instant now = Instant.now();
        if (createdAt == null) createdAt = now;
        if (occurredAt == null) occurredAt = now;
    }

    public Long getId() { return id; }
    public Long getRecipientId() { return recipientId; }
    public Long getActorId() { return actorId; }
    public Long getFollowId() { return followId; }
    public NotificationType getType() { return type; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getOccurredAt() { return occurredAt; }
    public Instant getReadAt() { return readAt; }

    /** Preserve the original event; move its displayed date on authorization. */
    public void markAsNewFollower(Instant authorizedAt) {
        type = NotificationType.NEW_FOLLOWER;
        occurredAt = Objects.requireNonNull(authorizedAt, "authorizedAt");
    }

    public void markRead(Instant at) {
        if (readAt == null) readAt = Objects.requireNonNull(at, "at");
    }

    public void clearFollowReference() {
        followId = null;
    }
}
