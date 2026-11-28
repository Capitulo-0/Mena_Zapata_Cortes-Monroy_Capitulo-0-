package com.capitulo0.backend.social.dto;

public record StoryRatingSummaryResponse(
    String storyKey,
    double averageRating,
    long ratingCount
) {}
