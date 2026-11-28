package com.capitulo0.backend.social.dto;

import com.capitulo0.backend.social.entity.ReviewVisibility;
import java.time.Instant;

public record OwnBookReviewResponse(
    Long id,
    Long bookId,
    int rating,
    String reviewText,
    ReviewVisibility visibility,
    Instant createdAt,
    Instant updatedAt
) {}
