package com.capitulo0.backend.user.dto;

import java.time.Instant;

public record PublicProfileResponse(
    Long id,
    String displayName,
    String username,
    String biography,
    String avatarUrl,
    Instant createdAt,
    Boolean isPrivate,
    Boolean canViewContent,
    Long followersCount,
    Long followingCount,
    Long booksCount,
    Boolean verifiedOrganizer,
    ReadingMoodResponse readingMood
) {}
