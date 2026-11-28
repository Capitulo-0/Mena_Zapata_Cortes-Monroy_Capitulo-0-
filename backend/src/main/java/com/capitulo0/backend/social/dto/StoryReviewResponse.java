package com.capitulo0.backend.social.dto;

import com.capitulo0.backend.social.entity.ReviewVisibility;
import java.time.Instant;
import java.util.Objects;

public record StoryReviewResponse(
    Long id,
    String storyKey,
    int rating,
    String reviewText,
    ReviewVisibility visibility,
    String username,
    String avatarUrl,
    boolean ownReview,
    Instant createdAt,
    Instant updatedAt
) {
    public StoryReviewResponse {
        Objects.requireNonNull(visibility, "visibility");
        if (visibility == ReviewVisibility.PRIVATE) {
            throw new IllegalArgumentException("Private reviews cannot be included in public responses");
        }
        if (visibility == ReviewVisibility.ANONYMOUS) {
            username = "@anonimo";
            avatarUrl = null;
        }
    }
}
