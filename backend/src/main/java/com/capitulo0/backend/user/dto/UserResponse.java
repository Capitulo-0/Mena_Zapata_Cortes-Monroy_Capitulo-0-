package com.capitulo0.backend.user.dto;

import java.time.Instant;

public record UserResponse(
    Long id,
    String email,
    String displayName,
    String username,
    String biography,
    String avatarUrl,
    Instant createdAt,
    Instant updatedAt
) {}
