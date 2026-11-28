package com.capitulo0.backend.social.entity;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "book_reviews")
public class BookReview {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(name = "book_id", nullable = false, updatable = false)
    private Long bookId;
    @Column(name = "user_id", nullable = false, updatable = false)
    private Long userId;
    @Column(nullable = false)
    private int rating;
    @Column(name = "review_text", length = 500)
    private String reviewText;
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private ReviewVisibility visibility;
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected BookReview() {}

    public Long getId() { return id; }
    public Long getBookId() { return bookId; }
    public Long getUserId() { return userId; }
    public int getRating() { return rating; }
    public String getReviewText() { return reviewText; }
    public ReviewVisibility getVisibility() { return visibility; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
}
