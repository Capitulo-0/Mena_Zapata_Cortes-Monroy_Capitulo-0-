package com.capitulo0.backend.social.dto;

public record BookRatingSummaryResponse(
    Long bookId,
    double averageRating,
    long ratingCount
) {}
