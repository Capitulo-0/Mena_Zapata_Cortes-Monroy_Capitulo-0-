package com.capitulo0.backend.follow.entity;

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

/** A directional follow relationship between two users. */
@Entity
@Table(name = "user_follows")
public class UserFollow {

    public enum Status {
        PENDING,
        ACCEPTED
    }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "follower_id", nullable = false)
    private Long followerId;

    @Column(name = "following_id", nullable = false)
    private Long followingId;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    private Status status;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "accepted_at")
    private Instant acceptedAt;

    protected UserFollow() {
        // Required by JPA.
    }

    private UserFollow(Long followerId, Long followingId, Status status) {
        this.followerId = Objects.requireNonNull(followerId, "followerId");
        this.followingId = Objects.requireNonNull(followingId, "followingId");
        this.status = Objects.requireNonNull(status, "status");
        if (followerId.equals(followingId)) {
            throw new IllegalArgumentException("A user cannot follow themselves");
        }
        if (status == Status.ACCEPTED) {
            this.acceptedAt = Instant.now();
        }
    }

    public static UserFollow pending(Long followerId, Long followingId) {
        return new UserFollow(followerId, followingId, Status.PENDING);
    }

    public static UserFollow accepted(Long followerId, Long followingId) {
        return new UserFollow(followerId, followingId, Status.ACCEPTED);
    }

    @PrePersist
    void beforeInsert() {
        if (createdAt == null) createdAt = Instant.now();
    }

    public void accept() {
        if (status != Status.PENDING) {
            throw new IllegalStateException("Only pending follow requests can be accepted");
        }
        status = Status.ACCEPTED;
        acceptedAt = Instant.now();
    }

    public Long getId() { return id; }
    public Long getFollowerId() { return followerId; }
    public Long getFollowingId() { return followingId; }
    public Status getStatus() { return status; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getAcceptedAt() { return acceptedAt; }
}
